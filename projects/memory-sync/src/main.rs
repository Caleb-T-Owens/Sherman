use anyhow::{Context, Result};
use clap::{Parser, Subcommand};

mod config;
mod git_ops;
mod sync;

use config::Config;

#[derive(Parser)]
#[command(name = "memory-sync")]
#[command(about = "Bidirectional sync for Sherman's memories to git", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize the workspace and clone the repository
    Init,
    /// Push local changes to remote
    Push,
    /// Pull remote changes to local
    Pull,
    /// Full bidirectional sync
    Sync,
    /// Check sync status and conflicts
    Status,
    /// Show current configuration
    Config,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let config = Config::load().context("Failed to load config")?;

    match cli.command {
        Some(Commands::Init) => {
            println!("Initializing memory sync workspace...");
            git_ops::init_workspace(&config)?;
            println!("✓ Workspace initialized at {}", config.workspace_path.display());
        }
        Some(Commands::Push) => {
            println!("Pushing local memories to remote...");
            sync::push(&config)?;
            println!("✓ Push complete");
        }
        Some(Commands::Pull) => {
            println!("Pulling remote memories to local...");
            sync::pull(&config)?;
            println!("✓ Pull complete");
        }
        Some(Commands::Sync) | None => {
            println!("Syncing memories bidirectionally...");
            sync::sync(&config)?;
        }
        Some(Commands::Status) => {
            sync::status(&config)?;
        }
        Some(Commands::Config) => {
            println!("Current configuration:");
            println!("{}", serde_json::to_string_pretty(&config)?);
        }
    }

    Ok(())
}
