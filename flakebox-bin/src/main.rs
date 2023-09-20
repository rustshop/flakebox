mod opts;

use std::fs;
use std::os::unix;
use std::path::Path;
use std::path::PathBuf;

use clap::Parser;
use error_stack::ResultExt;
use opts::Commands;
use opts::Opts;
use thiserror::Error;
use tracing_subscriber::EnvFilter;
use walkdir::WalkDir;

#[derive(Error, Debug)]
enum AppError {
    #[error("Io error: {0}")]
    Io(PathBuf),
}

type AppResult<T> = error_stack::Result<T, AppError>;

fn main() -> AppResult<()> {
    init_logging();
    let opts = Opts::parse();

    match opts.command {
        Commands::Init => init(&opts)?,
        Commands::Install => install(&opts)?,
    }

    Ok(())
}

impl Opts {
    fn share_dir(&self) -> &Path {
        &self.share_dir
    }
    fn project_root_dir(&self) -> &Path {
        &self.project_root_dir
    }

    fn project_root_overlay_src(&self) -> PathBuf {
        self.share_dir().join("project-root-overlay")
    }

    fn project_dot_config_dir(&self) -> PathBuf {
        self.project_root_dir().join(".config")
    }
    fn project_fakebox_share_stamp(&self) -> PathBuf {
        self.project_dot_config_dir().join("last-share")
    }
}

fn install(opts: &Opts) -> AppResult<()> {
    let root = opts.project_root_overlay_src();
    for entry in WalkDir::new(&root) {
        let entry = entry.change_context_lazy(|| AppError::Io(root.clone()))?;
        let source_path = entry.path();
        let metadata = fs::metadata(source_path)
            .change_context_lazy(|| AppError::Io(source_path.to_owned()))?;
        let relative_path = source_path.strip_prefix(&root).expect("Prefixed with root");
        let dst_path = opts.project_root_dir().join(relative_path);
        if metadata.is_dir() {
            fs::create_dir_all(dst_path)
                .change_context_lazy(|| AppError::Io(relative_path.to_owned()))?;
        } else {
            fs::copy(source_path, dst_path)
                .change_context_lazy(|| AppError::Io(relative_path.to_owned()))?;
        }
    }

    fs::create_dir_all(opts.project_dot_config_dir())
        .change_context_lazy(|| AppError::Io(opts.project_dot_config_dir()))?;

    unix::fs::symlink(opts.share_dir(), opts.project_fakebox_share_stamp())
        .change_context_lazy(|| AppError::Io(opts.project_fakebox_share_stamp()))?;

    Ok(())
}

fn init(opts: &Opts) -> AppResult<()> {
    let stamp_path = opts.project_fakebox_share_stamp();
    if !stamp_path.exists() {
        eprintln!("⚠️  Flakebox files not installed. Call `flakebox install`.");
        return Ok(());
    }

    let stamp = fs::read_link(&stamp_path).change_context_lazy(|| AppError::Io(stamp_path))?;

    if stamp != opts.share_dir {
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
