use std::fs::{File, OpenOptions, Permissions};
use std::io::ErrorKind;
use std::os::unix::fs::{PermissionsExt, symlink};
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

use error_stack::{Report, ResultExt};
use fs_err as fs;

use crate::{AppError, AppResult, Opts, check_project_root_env};

const COMMIT_TEMPLATE: &str = "misc/git-hooks/commit-template.txt";
const HOOK_NAMES: [&str; 2] = ["pre-commit", "commit-msg"];

#[derive(Clone, Copy)]
enum ConfigScope {
    Effective,
    Local,
    Worktree,
}

#[derive(Clone, Copy)]
enum OwnedConfigScope {
    Local,
    Worktree,
}

/// Installs the generated Git integration into the current repository.
pub(crate) fn install(opts: &Opts) -> AppResult<()> {
    check_project_root_env(opts)?;

    let project_root =
        fs::canonicalize(opts.project_root_dir_path()).change_context(AppError::IO)?;
    let candidate_root =
        fs::canonicalize(opts.root_dir_candidate_path()).change_context(AppError::IO)?;
    let git_common_dir = git_common_dir(&project_root)?;
    let git_dir = git_dir(&project_root)?;
    fs::create_dir_all(&git_common_dir).change_context(AppError::IO)?;

    let lock_path = git_common_dir.join("flakebox-install-hooks.lock");
    let lock = open_lock(&lock_path)?;
    lock.lock()
        .change_context(AppError::IO)
        .attach_printable_lazy(|| format!("could not lock {}", lock_path.display()))?;

    install_commit_template(&candidate_root, &project_root)?;
    install_hooks(&candidate_root, &project_root, &git_common_dir, &git_dir)?;
    Ok(())
}

fn open_lock(path: &Path) -> AppResult<File> {
    match OpenOptions::new().read(true).open(path) {
        Ok(lock) => Ok(lock),
        Err(error) if error.kind() == ErrorKind::NotFound => OpenOptions::new()
            .read(true)
            .write(true)
            .create_new(true)
            .open(path)
            .or_else(|error| {
                if error.kind() == ErrorKind::AlreadyExists {
                    OpenOptions::new().read(true).open(path)
                } else {
                    Err(error)
                }
            })
            .change_context(AppError::IO),
        Err(error) => Err(error).change_context(AppError::IO),
    }
}

fn git_common_dir(project_root: &Path) -> AppResult<PathBuf> {
    let output = git(
        project_root,
        ["rev-parse", "--path-format=absolute", "--git-common-dir"],
    )?;
    require_git_success(output, "could not find the Git common directory")
        .map(|stdout| PathBuf::from(stdout.strip_suffix('\n').unwrap_or(&stdout)))
}

fn git_dir(project_root: &Path) -> AppResult<PathBuf> {
    let output = git(
        project_root,
        ["rev-parse", "--path-format=absolute", "--git-dir"],
    )?;
    require_git_success(output, "could not find this worktree's Git directory")
        .map(|stdout| PathBuf::from(stdout.strip_suffix('\n').unwrap_or(&stdout)))
}

fn install_hooks(
    candidate_root: &Path,
    project_root: &Path,
    git_common_dir: &Path,
    git_dir: &Path,
) -> AppResult<()> {
    let hooks_dir = git_common_dir.join("hooks");
    let dispatchers_dir = hooks_dir.join("flakebox");
    let markers_dir = git_dir.join("flakebox/hooks");
    for name in HOOK_NAMES {
        let candidate = candidate_root.join(".config/flakebox/git-hooks").join(name);
        let hook = hooks_dir.join(name);
        let dispatcher = dispatchers_dir.join(name);
        let link_target = PathBuf::from("flakebox").join(name);
        let marker = markers_dir.join(format!("{name}-enabled"));

        if candidate.exists() {
            ensure_hook_replaceable(&hook, &link_target, project_root, name)?;
            fs::create_dir_all(&dispatchers_dir).change_context(AppError::IO)?;
            fs::create_dir_all(&markers_dir).change_context(AppError::IO)?;
            install_file(&candidate, &dispatcher)?;
            install_symlink(&link_target, &hook)?;
            install_marker(&marker)?;
        } else {
            remove_if_file(&marker)?;
            neutralize_legacy_hook(&hook, name, project_root)?;
        }
    }
    Ok(())
}

fn ensure_hook_replaceable(
    hook: &Path,
    installed_target: &Path,
    project_root: &Path,
    name: &str,
) -> AppResult<()> {
    let legacy_target = project_root.join("misc/git-hooks").join(name);
    match fs::read_link(hook) {
        Ok(target) if target == installed_target || target == legacy_target => Ok(()),
        Ok(target) => Err(Report::new(AppError::Project)).attach_printable(format!(
            "{} points to non-Flakebox target {}; preserve or remove it explicitly before \
             installing Flakebox hooks",
            hook.display(),
            target.display()
        )),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(_) if hook.symlink_metadata().is_ok() => Err(Report::new(AppError::Project))
            .attach_printable(format!(
                "{} is not a Flakebox-owned symlink; preserve or remove it explicitly before \
                 installing Flakebox hooks",
                hook.display()
            )),
        Err(error) => Err(error).change_context(AppError::IO),
    }
}

fn neutralize_legacy_hook(hook: &Path, name: &str, project_root: &Path) -> AppResult<()> {
    let legacy_suffix = Path::new("misc/git-hooks").join(name);
    let target = match fs::read_link(hook) {
        Ok(target) => target,
        Err(error) if error.kind() == ErrorKind::NotFound => return Ok(()),
        Err(_)
            if hook
                .symlink_metadata()
                .is_ok_and(|metadata| !metadata.is_symlink()) =>
        {
            return Ok(());
        }
        Err(error) => {
            return Err(error)
                .change_context(AppError::IO)
                .attach_printable_lazy(|| format!("could not inspect {}", hook.display()));
        }
    };
    if target == project_root.join(&legacy_suffix) {
        return fs::remove_file(hook).change_context(AppError::IO);
    }
    if target.ends_with(legacy_suffix) {
        return Err(Report::new(AppError::Project)).attach_printable(format!(
            "{} points to an ambiguous legacy-style target {}; inspect linked worktrees and \
             remove or migrate the link explicitly",
            hook.display(),
            target.display()
        ));
    }
    Ok(())
}

fn install_marker(destination: &Path) -> AppResult<()> {
    if fs::read(destination).is_ok_and(|contents| contents == b"enabled\n") {
        return Ok(());
    }
    let temporary = temporary_path(destination);
    remove_if_file(&temporary)?;
    fs::write(&temporary, b"enabled\n").change_context(AppError::IO)?;
    rename_into_place(&temporary, destination)
}

fn install_file(source: &Path, destination: &Path) -> AppResult<()> {
    let source_contents = fs::read(source).change_context(AppError::IO)?;
    let source_mode = fs::metadata(source)
        .change_context(AppError::IO)?
        .permissions()
        .mode();
    if fs::read(destination).is_ok_and(|installed| installed == source_contents)
        && fs::metadata(destination)
            .is_ok_and(|metadata| metadata.permissions().mode() & 0o111 == source_mode & 0o111)
    {
        return Ok(());
    }

    let temporary = temporary_path(destination);
    remove_if_file(&temporary)?;
    fs::write(&temporary, source_contents).change_context(AppError::IO)?;
    fs::set_permissions(&temporary, Permissions::from_mode(source_mode))
        .change_context(AppError::IO)?;
    rename_into_place(&temporary, destination)
}

fn install_symlink(source: &Path, destination: &Path) -> AppResult<()> {
    if fs::read_link(destination).is_ok_and(|installed| installed == source) {
        return Ok(());
    }

    let temporary = temporary_path(destination);
    remove_if_file(&temporary)?;
    symlink(source, &temporary).change_context(AppError::IO)?;
    rename_into_place(&temporary, destination)
}

fn temporary_path(destination: &Path) -> PathBuf {
    destination.with_extension(format!("flakebox-new-{}", std::process::id()))
}

fn rename_into_place(temporary: &Path, destination: &Path) -> AppResult<()> {
    if let Err(error) = fs::rename(temporary, destination) {
        let _ = fs::remove_file(temporary);
        return Err(error)
            .change_context(AppError::IO)
            .attach_printable_lazy(|| {
                format!("could not atomically install {}", destination.display())
            });
    }
    Ok(())
}

fn remove_if_file(path: &Path) -> AppResult<()> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error).change_context(AppError::IO),
    }
}

fn install_commit_template(candidate_root: &Path, project_root: &Path) -> AppResult<()> {
    let enabled = candidate_root.join(COMMIT_TEMPLATE).exists();
    let expected = nul_terminated(COMMIT_TEMPLATE);

    if enabled {
        enable_worktree_config(project_root)?;
        remove_legacy_template(project_root, &expected)?;
        if git_config_value(project_root, ConfigScope::Effective)?.as_deref()
            != Some(expected.as_slice())
        {
            let output = git(
                project_root,
                ["config", "--worktree", "commit.template", COMMIT_TEMPLATE],
            )?;
            require_git_success(output, "could not configure commit.template")?;
        }
    } else {
        if worktree_config_enabled(project_root)?
            && git_config_value(project_root, ConfigScope::Worktree)?.as_deref()
                == Some(expected.as_slice())
        {
            unset_config_value(project_root, OwnedConfigScope::Worktree)?;
        }
        remove_legacy_template(project_root, &expected)?;
    }
    Ok(())
}

fn enable_worktree_config(project_root: &Path) -> AppResult<()> {
    if worktree_config_enabled(project_root)? {
        return Ok(());
    }

    if local_config_values(project_root, "core.worktree")?.is_some() {
        return Err(Report::new(AppError::Project)).attach_printable(
            "cannot enable extensions.worktreeConfig while local core.worktree is set; \
             migrate core.worktree to worktree config as described by git-config(1), then retry",
        );
    }
    match local_config_values(project_root, "core.bare")? {
        None => {}
        Some(value) if value == b"false\0" => {
            let output = git(
                project_root,
                ["config", "--local", "--unset-all", "core.bare"],
            )?;
            require_git_success(output, "could not migrate the default core.bare value")?;
        }
        Some(_) => {
            return Err(Report::new(AppError::Project)).attach_printable(
                "cannot enable extensions.worktreeConfig while non-default local core.bare is set; \
                 migrate core.bare to worktree config as described by git-config(1), then retry",
            );
        }
    }

    let output = git(
        project_root,
        ["config", "--local", "extensions.worktreeConfig", "true"],
    )?;
    require_git_success(output, "could not enable worktree Git configuration")?;
    Ok(())
}

fn worktree_config_enabled(project_root: &Path) -> AppResult<bool> {
    let output = git(
        project_root,
        [
            "config",
            "--local",
            "--type=bool",
            "--get",
            "extensions.worktreeConfig",
        ],
    )?;
    if output.status.success() {
        Ok(output.stdout == b"true\n")
    } else if output.status.code() == Some(1) {
        Ok(false)
    } else {
        require_git_success(output, "could not inspect extensions.worktreeConfig").map(|_| false)
    }
}

fn local_config_values(project_root: &Path, key: &str) -> AppResult<Option<Vec<u8>>> {
    let output = git_args(
        project_root,
        &["config", "--local", "--null", "--get-all", key],
    )?;
    if output.status.success() {
        Ok(Some(output.stdout))
    } else if output.status.code() == Some(1) {
        Ok(None)
    } else {
        require_git_success(output, &format!("could not inspect {key}")).map(|_| None)
    }
}

fn remove_legacy_template(project_root: &Path, expected: &[u8]) -> AppResult<()> {
    if git_config_value(project_root, ConfigScope::Local)?.as_deref() == Some(expected) {
        unset_config_value(project_root, OwnedConfigScope::Local)?;
    }
    Ok(())
}

fn git_config_value(project_root: &Path, scope: ConfigScope) -> AppResult<Option<Vec<u8>>> {
    let mut args = vec!["config"];
    match scope {
        ConfigScope::Effective => {}
        ConfigScope::Local => args.push("--local"),
        ConfigScope::Worktree => args.push("--worktree"),
    }
    args.extend([
        "--null",
        match scope {
            ConfigScope::Effective => "--get",
            ConfigScope::Local | ConfigScope::Worktree => "--get-all",
        },
        "commit.template",
    ]);
    let output = git_args(project_root, &args)?;
    if output.status.success() {
        Ok(Some(output.stdout))
    } else if output.status.code() == Some(1) {
        Ok(None)
    } else {
        require_git_success(output, "could not inspect commit.template").map(|_| None)
    }
}

fn unset_config_value(project_root: &Path, scope: OwnedConfigScope) -> AppResult<()> {
    let scope_arg = match scope {
        OwnedConfigScope::Local => "--local",
        OwnedConfigScope::Worktree => "--worktree",
    };
    let output = git(
        project_root,
        ["config", scope_arg, "--unset-all", "commit.template"],
    )?;
    require_git_success(output, "could not remove commit.template")?;
    Ok(())
}

fn nul_terminated(value: &str) -> Vec<u8> {
    let mut bytes = value.as_bytes().to_vec();
    bytes.push(0);
    bytes
}

fn git<const N: usize>(project_root: &Path, args: [&str; N]) -> AppResult<Output> {
    git_args(project_root, &args)
}

fn git_args(project_root: &Path, args: &[&str]) -> AppResult<Output> {
    Command::new("git")
        .arg("-C")
        .arg(project_root)
        .args(args)
        .output()
        .change_context(AppError::IO)
}

fn require_git_success(output: Output, message: &str) -> AppResult<String> {
    if output.status.success() {
        return Ok(String::from_utf8_lossy(&output.stdout).into_owned());
    }

    Err(Report::new(AppError::Project)).attach_printable(format!(
        "{message}: {}",
        String::from_utf8_lossy(&output.stderr).trim_end()
    ))
}
