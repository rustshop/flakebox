use std::path::PathBuf;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
pub struct Opts {
    #[arg(long, env = "FLAKEBOX_SHARE_DIR_CANDIDATE")]
    pub share_dir_candidate: PathBuf,

    #[arg(long, env = "FLAKEBOX_PROJECT_ROOT_DIR")]
    pub project_root_dir: PathBuf,

    #[arg(long, env = "FLAKEBOX_PROJECT_SHARE_DIR")]
    pub project_share_dir: PathBuf,

    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    Init,
    Install,
    Docs {
        #[arg(long, env = "FLAKEBOX_DOCS_DIR")]
        docs_dir: PathBuf,
    },
}
