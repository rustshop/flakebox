mod opts;

use std::fs::{Permissions, set_permissions};
use std::io;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use clap::Parser;
use duct::cmd;
use error_stack::ResultExt;
use fs_err as fs;
use opts::{Commands, Opts};
use serde::Deserialize;
use thiserror::Error;
use toml_edit::value;
use tracing_subscriber::EnvFilter;
use walkdir::WalkDir;

#[derive(Error, Debug, PartialEq, Eq)]
enum AppError {
    #[error("application error")]
    General,
    #[error("project error")]
    Project,
    #[error("IO error")]
    IO,
    #[error("Lint problem")]
    Lint,
}

type AppResult<T> = error_stack::Result<T, AppError>;

fn main() -> AppResult<()> {
    init_logging();
    let opts = Opts::parse();

    match opts.command {
        Commands::Init => init(&opts)?,
        Commands::Install => install(&opts)?,
        Commands::Docs { docs_dir } => docs_dir.map_or_else(
            || {
                cmd!("nix", "build", "github:rustshop/flakebox#docs")
                    .run()
                    .change_context(AppError::General)?;
                cmd!("xdg-open", "result/index.html")
                    .run()
                    .change_context(AppError::General)?;
                Ok::<(), error_stack::Report<AppError>>(())
            },
            |docs_dir| {
                let docs_index = docs_dir.join("index.html");
                eprintln!("Opening docs available at {}", docs_index.display());
                cmd!("xdg-open", docs_index)
                    .run()
                    .change_context(AppError::General)?;
                Ok::<(), error_stack::Report<AppError>>(())
            },
        )?,
        Commands::Lint { fix, silent } => match lint(&opts, fix, silent) {
            Err(e) if e.current_context() == &AppError::Lint => std::process::exit(1),
            other => other,
        }?,
    }

    Ok(())
}

impl Opts {
    fn root_dir_candidate_path(&self) -> &Path {
        &self.root_dir_candidate
    }

    fn root_dir_candidate_id_path(&self) -> PathBuf {
        self.root_dir_candidate
            .join(".config")
            .join("flakebox")
            .join("id")
    }

    fn project_root_dir_path(&self) -> &Path {
        &self.project_root_dir
    }

    fn current_root_dir_id_path(&self) -> PathBuf {
        self.project_root_dir
            .join(".config")
            .join("flakebox")
            .join("id")
    }
}

type LintFixFn = fn(opts: &Opts) -> AppResult<()>;

struct LintItem {
    path: PathBuf,
    msg: String,
    fix: Option<LintFixFn>,
}

fn lint_cargo_toml_fix_resolver_v2(opts: &Opts) -> AppResult<()> {
    let (path, mut cargo_toml) = load_root_cargo_toml(opts)?;

    cargo_toml["workspace"]["resolver"] = value("2");

    fs::write(path, cargo_toml.to_string()).change_context(AppError::IO)?;

    Ok(())
}

fn lint_cargo_toml_fix_ci_build_profile(opts: &Opts) -> AppResult<()> {
    let (path, mut cargo_toml) = load_root_cargo_toml(opts)?;

    set_cargo_profile_defaults(&mut cargo_toml);

    fs::write(path, cargo_toml.to_string()).change_context(AppError::IO)?;

    Ok(())
}

fn set_cargo_profile_defaults(cargo_toml: &mut toml_edit::DocumentMut) {
    if cargo_toml.get("profile").is_none() {
        cargo_toml["profile"] = toml_edit::Item::Table(toml_edit::Table::new());
    }

    let profiles = item_as_table_mut(&mut cargo_toml["profile"], "Cargo profiles must be a table");
    if !profiles.contains_key("dev") {
        profiles["dev"] = toml_edit::Item::Table(toml_edit::Table::new());
    }
    profiles["dev"]["debug"] = value(false);
    set_dependency_debug_override(cargo_toml, "dev");

    cargo_toml["profile"]["ci"] = toml_edit::Item::Table(toml_edit::Table::new());
    cargo_toml["profile"]["ci"]["debug"] = value(false);
    cargo_toml["profile"]["ci"]["inherits"] = value("dev");
    cargo_toml["profile"]["ci"]["incremental"] = value(false);
    cargo_toml["profile"]["ci"]["lto"] = value("off");
    set_dependency_debug_override(cargo_toml, "ci");
}

fn set_dependency_debug_override(cargo_toml: &mut toml_edit::DocumentMut, profile: &str) {
    let profile = item_as_table_mut(
        &mut cargo_toml["profile"][profile],
        "Cargo profile must be a table",
    );
    if !profile.contains_key("package") {
        profile["package"] = toml_edit::Item::Table(toml_edit::Table::new());
    }

    let package = item_as_table_mut(
        &mut profile["package"],
        "Cargo profile package overrides must be a table",
    );
    if !package.contains_key("*") {
        package["*"] = toml_edit::Item::Table(toml_edit::Table::new());
    }

    let dependency_override = item_as_table_mut(
        &mut package["*"],
        "Cargo dependency profile override must be a table",
    );
    dependency_override["debug"] = value(false);
    dependency_override
        .key_mut("debug")
        .expect("debug was just inserted")
        .leaf_decor_mut()
        .set_prefix(
            "# Keep dependencies without debug information if the workspace profile is\n\
             # changed to \"line-tables-only\" for more useful workspace panic traces.\n",
        );
}

fn item_as_table_mut<'item>(
    item: &'item mut toml_edit::Item,
    invalid_message: &str,
) -> &'item mut toml_edit::Table {
    if !item.is_table() {
        let owned = std::mem::take(item);
        *item = toml_edit::Item::Table(owned.into_table().expect(invalid_message));
    }

    item.as_table_mut()
        .expect("item was already a table or was converted to one")
}

fn lint_cargo_toml(opts: &Opts, problems: &mut Vec<LintItem>) -> AppResult<()> {
    let (path, cargo_toml) = load_root_cargo_toml(opts)?;

    if let Some(toml_edit::Item::Table(workspace)) = cargo_toml.get("workspace")
        && !workspace_resolver_is_supported(workspace)
    {
        problems.push(LintItem {
            path: path.clone(),
            msg: "`workspace.resolver` missing or not set to '2' or '3'".to_string(),
            fix: Some(lint_cargo_toml_fix_resolver_v2),
        });
    }
    if cargo_toml
        .get("profile")
        .and_then(|profile| profile.get("ci"))
        .is_none()
    {
        problems.push(LintItem {
            path,
            msg: "`profile.ci` missing".to_string(),
            fix: Some(lint_cargo_toml_fix_ci_build_profile),
        });
    }
    Ok(())
}

fn workspace_resolver_is_supported(workspace: &toml_edit::Table) -> bool {
    matches!(
        workspace.get("resolver"),
        Some(toml_edit::Item::Value(toml_edit::Value::String(resolver)))
            if resolver.value() == "2" || resolver.value() == "3"
    )
}

#[derive(Deserialize)]
struct CargoMetadataOutput {
    workspace_root: PathBuf,
}

fn detect_cargo_root(_opts: &Opts) -> AppResult<PathBuf> {
    let output = cmd!("cargo", "metadata", "--no-deps", "--format-version", "1")
        .read()
        .change_context(AppError::IO)?;
    let metdata: CargoMetadataOutput =
        serde_json::from_str(&output).change_context(AppError::IO)?;
    Ok(metdata.workspace_root)
}

fn load_root_cargo_toml(
    opts: &Opts,
) -> Result<(PathBuf, toml_edit::DocumentMut), error_stack::Report<AppError>> {
    let path = detect_cargo_root(opts)?.join("Cargo.toml");
    let cargo_toml = fs::read_to_string(&path).change_context(AppError::IO)?;
    let cargo_toml = cargo_toml
        .parse::<toml_edit::DocumentMut>()
        .change_context(AppError::IO)?;
    Ok((path, cargo_toml))
}

fn lint(opts: &Opts, fix: bool, silent: bool) -> AppResult<()> {
    check_project_root_env(opts)?;
    let mut found_problems = vec![];
    let mut remaining_problems = vec![];
    #[allow(clippy::single_element_loop)] // silence, I'll add more soon
    for lint_fn in [lint_cargo_toml] {
        lint_fn(opts, &mut found_problems)?;
    }

    for problem in found_problems {
        match (problem.fix.as_ref(), fix) {
            (Some(fix_fn), true) => {
                fix_fn(opts)?;
            }
            _ => {
                if !silent {
                    println!("{}: {}", problem.path.display(), problem.msg);
                }
                remaining_problems.push(problem);
            }
        }
    }
    if !silent && remaining_problems.iter().any(|f| f.fix.is_some()) {
        println!("Automatic fixes available. Call `flakebox lint --fix`");
    }
    if !remaining_problems.is_empty() {
        Err(AppError::Lint)?
    }
    Ok(())
}

fn install(opts: &Opts) -> AppResult<()> {
    check_project_root_env(opts)?;

    install_files(opts.root_dir_candidate_path(), opts.project_root_dir_path())
        .change_context(AppError::General)?;

    Ok(())
}

fn check_project_root_env(opts: &Opts) -> AppResult<()> {
    let cargo_toml_path = detect_cargo_root(opts)?.join("Cargo.toml");
    if !cargo_toml_path.exists() {
        return Err(AppError::Project).attach_printable_lazy(|| {
            format!("No Cargo.toml found at {}", cargo_toml_path.display())
        });
    }

    if !opts.project_root_dir_path().join("flake.nix").exists() {
        return Err(AppError::Project).attach_printable("No flake.nix in project root directory");
    }

    Ok(())
}

fn install_files(src: &Path, dst: &Path) -> AppResult<()> {
    for entry in WalkDir::new(src) {
        let entry = entry.change_context_lazy(|| AppError::IO)?;
        let source_path = entry.path();
        let metadata = fs::metadata(source_path).change_context_lazy(|| AppError::IO)?;
        let relative_path = source_path.strip_prefix(src).expect("Prefixed with root");
        let dst_path = dst.join(relative_path);
        if metadata.is_dir() {
            fs::create_dir_all(dst_path).change_context_lazy(|| AppError::IO)?;
        } else {
            remove_file_or_symlink(&dst_path).change_context_lazy(|| AppError::IO)?;
            fs::copy(source_path, &dst_path).change_context_lazy(|| AppError::IO)?;
            if let Err(error) = cmd!("git", "add", &dst_path).run() {
                tracing::debug!(%error, path = %dst_path.display(), "could not stage installed file");
            }

            chmod_non_writable(&dst_path)?;
        }
    }

    Ok(())
}

fn chmod_non_writable(path: &Path) -> AppResult<()> {
    let current_permissions = fs::metadata(path)
        .change_context_lazy(|| AppError::IO)?
        .permissions()
        .mode();
    set_permissions(path, Permissions::from_mode(current_permissions & !(0o222)))
        .change_context_lazy(|| AppError::IO)?;
    Ok(())
}

fn remove_file_or_symlink(path: &Path) -> io::Result<()> {
    if path.symlink_metadata().is_ok() {
        fs::remove_file(path)?;
    }

    Ok(())
}

fn init(opts: &Opts) -> AppResult<()> {
    let current_id_path = opts.current_root_dir_id_path();
    if !current_id_path.exists() {
        eprintln!("⚠️  Flakebox files not installed. Call `flakebox install`.");
        return Ok(());
    }

    let id = fs::read_to_string(&current_id_path)
        .change_context_lazy(|| AppError::General)
        .attach_printable_lazy(|| {
            format!(
                "data dir id {} file not readable",
                current_id_path.display()
            )
        })?;

    let root_dir_candidate_id = opts.root_dir_candidate_id_path();
    let candidate_id = fs::read_to_string(root_dir_candidate_id)
        .change_context_lazy(|| AppError::General)
        .attach_printable("data dir id file not readable")?;

    if id != candidate_id {
        eprintln!("ℹ️  Flakebox files not up to date. Call `flakebox install`.");
        return Ok(());
    }

    Ok(())
}

fn init_logging() {
    let subscriber = tracing_subscriber::fmt()
        .with_writer(std::io::stderr) // Print to stderr
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive("info".parse().expect("info is a valid filter directive"))
                .from_env_lossy(),
        )
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("Failed to set tracing subscriber");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cargo_workspace_resolver_accepts_current_versions() {
        for resolver in ["2", "3"] {
            let cargo_toml = format!("[workspace]\nresolver = \"{resolver}\"\n")
                .parse::<toml_edit::DocumentMut>()
                .expect("valid test manifest");
            let workspace = cargo_toml["workspace"]
                .as_table()
                .expect("workspace is a table");

            assert!(workspace_resolver_is_supported(workspace));
        }
    }

    #[test]
    fn cargo_workspace_resolver_rejects_stale_or_invalid_values() {
        for manifest in [
            "[workspace]\n",
            "[workspace]\nresolver = \"1\"\n",
            "[workspace]\nresolver = 3\n",
        ] {
            let cargo_toml = manifest
                .parse::<toml_edit::DocumentMut>()
                .expect("valid test manifest");
            let workspace = cargo_toml["workspace"]
                .as_table()
                .expect("workspace is a table");

            assert!(!workspace_resolver_is_supported(workspace));
        }
    }

    #[test]
    fn cargo_profile_defaults_disable_debug_info_and_preserve_inline_dev_settings() {
        let mut cargo_toml = "profile = { dev = { package = { \"*\" = { opt-level = 1 } } } }\n"
            .parse::<toml_edit::DocumentMut>()
            .expect("valid test manifest");

        set_cargo_profile_defaults(&mut cargo_toml);

        assert_eq!(cargo_toml["profile"]["dev"]["debug"].as_bool(), Some(false));
        assert_eq!(
            cargo_toml["profile"]["dev"]["package"]["*"]["debug"].as_bool(),
            Some(false)
        );
        assert_eq!(
            cargo_toml["profile"]["dev"]["package"]["*"]["opt-level"].as_integer(),
            Some(1)
        );
        assert_eq!(cargo_toml["profile"]["ci"]["debug"].as_bool(), Some(false));
        assert_eq!(
            cargo_toml["profile"]["ci"]["package"]["*"]["debug"].as_bool(),
            Some(false)
        );

        let cargo_toml = cargo_toml.to_string();
        assert!(cargo_toml.contains(
            "[profile.dev.package.\"*\"]\n\
             opt-level = 1\n\
             # Keep dependencies without debug information if the workspace profile is\n\
             # changed to \"line-tables-only\" for more useful workspace panic traces.\n\
             debug = false"
        ));
        assert!(cargo_toml.contains(
            "[profile.ci.package.\"*\"]\n\
             # Keep dependencies without debug information if the workspace profile is\n\
             # changed to \"line-tables-only\" for more useful workspace panic traces.\n\
             debug = false"
        ));
        assert_eq!(
            cargo_toml
                .matches(
                    "# changed to \"line-tables-only\" for more useful workspace panic traces."
                )
                .count(),
            2
        );
    }
}
