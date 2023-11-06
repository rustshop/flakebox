mod opts;

use std::fs::{set_permissions, Permissions};
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
        Commands::Docs { docs_dir } => {
            if let Some(docs_dir) = docs_dir {
                let docs_index = docs_dir.join("index.html");
                eprintln!("Opening docs available at {}", docs_index.display());
                cmd!("xdg-open", docs_index)
                    .run()
                    .change_context(AppError::General)?;
            } else {
                cmd!("nix", "build", "github:rustshop/flakebox#docs")
                    .run()
                    .change_context(AppError::General)?;
                cmd!("xdg-open", "result/index.html")
                    .run()
                    .change_context(AppError::General)?;
            }
        }
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

    if cargo_toml.get("profile").is_none() {
        cargo_toml["profile"] = toml_edit::Item::Table(toml_edit::Table::new());
    }

    cargo_toml["profile"]["ci"] = toml_edit::Item::Table(toml_edit::Table::new());
    cargo_toml["profile"]["ci"]["inherits"] = value("dev");
    cargo_toml["profile"]["ci"]["incremental"] = value(false);
    cargo_toml["profile"]["ci"]["debug"] = value("line-tables-only");
    cargo_toml["profile"]["ci"]["lto"] = value("off");

    fs::write(path, cargo_toml.to_string()).change_context(AppError::IO)?;

    Ok(())
}

fn lint_cargo_toml(opts: &Opts, problems: &mut Vec<LintItem>) -> AppResult<()> {
    let (path, cargo_toml) = load_root_cargo_toml(opts)?;

    if let Some(toml_edit::Item::Table(ref workspace)) = cargo_toml.get("workspace") {
        match workspace.get("resolver") {
            Some(toml_edit::Item::Value(toml_edit::Value::String(ref v))) if v.value() == "2" => {}
            _ => {
                problems.push(LintItem {
                    path: path.clone(),
                    msg: "`workspace.resolver` missing or not set to 'v2'".to_string(),
                    fix: Some(lint_cargo_toml_fix_resolver_v2),
                });
            }
        }
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
) -> Result<(PathBuf, toml_edit::Document), error_stack::Report<AppError>> {
    let path = detect_cargo_root(opts)?.join("Cargo.toml");
    let cargo_toml = fs::read_to_string(&path).change_context(AppError::IO)?;
    let cargo_toml = cargo_toml
        .parse::<toml_edit::Document>()
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
            let _ = cmd!("git", "add", &dst_path).run();

            chmod_non_writeable(&dst_path)?;
        }
    }

    Ok(())
}

fn chmod_non_writeable(path: &Path) -> AppResult<()> {
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
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .finish();

    tracing::subscriber::set_global_default(subscriber).expect("Failed to set tracing subscriber");
}
