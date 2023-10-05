mod opts;

use std::fs::{set_permissions, Permissions};
use std::os::unix;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::{env, fs, io};

use clap::Parser;
use duct::cmd;
use error_stack::ResultExt;
use opts::{Commands, Opts};
use thiserror::Error;
use tracing_subscriber::EnvFilter;
use walkdir::WalkDir;

#[derive(Error, Debug)]
enum AppError {
    #[error("application error")]
    General,
    #[error("must be run in project directory")]
    CwdOutside,
}

type AppResult<T> = error_stack::Result<T, AppError>;

fn main() -> AppResult<()> {
    init_logging();
    let opts = Opts::parse();

    match opts.command {
        Commands::Init => init(&opts)?,
        Commands::Install => install(&opts).change_context(AppError::General)?,
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
    }

    Ok(())
}

impl Opts {
    fn root_dir_candidate(&self) -> &Path {
        &self.root_dir_candidate
    }

    fn project_root_dir(&self) -> &Path {
        &self.project_root_dir
    }

    fn current_root_dir_path(&self) -> PathBuf {
        self.project_root_dir
            .join(".config")
            .join("flakebox")
            .join("current")
    }
    fn current_root_dir_path_cwd_rel(&self) -> AppResult<PathBuf> {
        let current_dir = env::current_dir().expect("Failed to get current directory");

        Ok(self
            .current_root_dir_path()
            .strip_prefix(&current_dir)
            .change_context(AppError::CwdOutside)?
            .to_owned())
    }
}

#[derive(Error, Debug)]
enum InstallError {
    #[error("IO error: {0}")]
    PathIo(PathBuf),
    #[error("Dir creation error: {0}")]
    CreateDir(PathBuf),
    #[error("Copy file error: {src} -> {dst}")]
    CopyError { src: PathBuf, dst: PathBuf },
    #[error("Wrong usage")]
    Usage,
}

type InstallResult<T> = error_stack::Result<T, InstallError>;

fn install(opts: &Opts) -> InstallResult<()> {
    if !opts.project_root_dir().join("Cargo.toml").exists() {
        return Err(InstallError::Usage)
            .attach_printable("No Cargo.toml in project root directory");
    }

    if !opts.project_root_dir().join("flake.nix").exists() {
        return Err(InstallError::Usage).attach_printable("No flake.nix in project root directory");
    }

    install_files(opts.root_dir_candidate(), opts.project_root_dir())?;

    let current = opts.current_root_dir_path();
    remove_symlink(&current)
        .change_context_lazy(|| InstallError::PathIo(opts.current_root_dir_path()))?;
    fs::create_dir_all(
        current
            .parent()
            .ok_or_else(|| InstallError::CreateDir(current.to_owned()))?,
    )
    .change_context_lazy(|| InstallError::CreateDir(current.to_owned()))?;
    unix::fs::symlink(opts.root_dir_candidate(), &current)
        .change_context_lazy(|| InstallError::PathIo(current.to_owned()))?;

    let _ = cmd!(
        "git",
        "add",
        &opts
            .current_root_dir_path_cwd_rel()
            .change_context(InstallError::Usage)?
    )
    .run();

    Ok(())
}

fn install_files(src: &Path, dst: &Path) -> InstallResult<()> {
    for entry in WalkDir::new(src) {
        let entry = entry.change_context_lazy(|| InstallError::PathIo(src.to_owned()))?;
        let source_path = entry.path();
        let metadata = fs::metadata(source_path)
            .change_context_lazy(|| InstallError::PathIo(source_path.to_owned()))?;
        let relative_path = source_path.strip_prefix(src).expect("Prefixed with root");
        let dst_path = dst.join(relative_path);
        if metadata.is_dir() {
            fs::create_dir_all(dst_path)
                .change_context_lazy(|| InstallError::PathIo(relative_path.to_owned()))?;
        } else {
            remove_symlink(&dst_path)
                .change_context_lazy(|| InstallError::PathIo(dst_path.to_owned()))?;
            fs::copy(source_path, &dst_path).change_context_lazy(|| InstallError::CopyError {
                src: source_path.to_owned(),
                dst: dst_path.to_owned(),
            })?;
            let _ = cmd!("git", "add", &relative_path).run();

            chmod_non_writeable(relative_path)?;
        }
    }

    Ok(())
}

fn chmod_non_writeable(relative_path: &Path) -> Result<(), error_stack::Report<InstallError>> {
    let current_permissions = fs::metadata(relative_path)
        .change_context_lazy(|| InstallError::PathIo(relative_path.to_owned()))?
        .permissions()
        .mode();
    set_permissions(
        relative_path,
        Permissions::from_mode(current_permissions & !(0o222)),
    )
    .change_context_lazy(|| InstallError::PathIo(relative_path.to_owned()))?;
    Ok(())
}

fn remove_symlink(path: &Path) -> io::Result<()> {
    if path.symlink_metadata().is_ok() {
        fs::remove_file(path)?;
    }

    Ok(())
}

fn init(opts: &Opts) -> AppResult<()> {
    let project_fakebox_share_dir = opts.current_root_dir_path();
    if !project_fakebox_share_dir.exists() {
        eprintln!("⚠️  Flakebox files not installed. Call `flakebox install`.");
        return Ok(());
    }

    let current_share_dir =
        fs::read_link(project_fakebox_share_dir).change_context_lazy(|| AppError::General)?;

    if current_share_dir != opts.root_dir_candidate() {
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
