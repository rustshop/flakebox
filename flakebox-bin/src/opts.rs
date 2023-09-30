use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
pub struct Opts {
    #[arg(long, env = "FLAKEBOX_ROOT_DIR_CANDIDATE")]
    pub root_dir_candidate: PathBuf,

    #[arg(long, env = "FLAKEBOX_PROJECT_ROOT_DIR")]
    pub project_root_dir: PathBuf,

    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    Init,
    Install,
    Docs {
        #[arg(long, env = "FLAKEBOX_DOCS_DIR")]
        docs_dir: Option<PathBuf>,
    },
}
