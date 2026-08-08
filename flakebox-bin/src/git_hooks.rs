mod hook_plan;
mod install_plan;
mod path_state;
mod template_plan;

use std::fs::{File, OpenOptions};
use std::io::ErrorKind;
use std::os::unix::ffi::OsStringExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

use error_stack::{Report, ResultExt};
use fs_err as fs;
use install_plan::InstallPlan;

use crate::{AppError, AppResult, Opts, check_project_root_env};

pub(super) const COMMIT_TEMPLATE: &str = "misc/git-hooks/commit-template.txt";
pub(super) const HOOK_NAMES: [&str; 2] = ["pre-commit", "commit-msg"];

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

    InstallPlan::validate(&candidate_root, &project_root, &git_common_dir, &git_dir)?.apply()
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
    git_path_output(output, "could not find the Git common directory")
}

fn git_dir(project_root: &Path) -> AppResult<PathBuf> {
    let output = git(
        project_root,
        ["rev-parse", "--path-format=absolute", "--git-dir"],
    )?;
    git_path_output(output, "could not find this worktree's Git directory")
}

fn git_path_output(output: Output, message: &str) -> AppResult<PathBuf> {
    if !output.status.success() {
        return require_git_success(output, message).map(PathBuf::from);
    }
    let mut bytes = output.stdout;
    if bytes.last() == Some(&b'\n') {
        bytes.pop();
    }
    Ok(PathBuf::from(std::ffi::OsString::from_vec(bytes)))
}

pub(super) fn git<const N: usize>(project_root: &Path, args: [&str; N]) -> AppResult<Output> {
    git_args(project_root, &args)
}

pub(super) fn git_args(project_root: &Path, args: &[&str]) -> AppResult<Output> {
    Command::new("git")
        .arg("-C")
        .arg(project_root)
        .args(args)
        .output()
        .change_context(AppError::IO)
}

pub(super) fn require_git_success(output: Output, message: &str) -> AppResult<String> {
    if output.status.success() {
        return Ok(String::from_utf8_lossy(&output.stdout).into_owned());
    }

    Err(Report::new(AppError::Project)).attach_printable(format!(
        "{message}: {}",
        String::from_utf8_lossy(&output.stderr).trim_end()
    ))
}

#[cfg(test)]
#[path = "git_hooks_tests.rs"]
mod tests;
