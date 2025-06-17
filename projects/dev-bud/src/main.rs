use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod utils;

use commands::{
    create_bud_file, delete_bud_file, execute_command, list_bud_files, open_bud_file,
    switch_current_file,
};
use utils::find_root_dir;

use crate::utils::get_current_file;

#[derive(Parser)]
#[command(name = "dev-bud")]
#[command(about = "A development assistant tool")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// List all markdown files in the .bud directory
    List,
    /// Create a new markdown file in the .bud directory
    Create {
        /// Name of the file to create (without .md extension, no partial matching)
        name: String,
    },
    /// Open a markdown file in Cursor
    Open {
        /// Name of the file to open (supports partial matching)
        name: Option<String>,
    },
    /// Switch the current file
    Switch {
        /// Name of the file to switch to (supports partial matching)
        name: String,
    },
    /// Show the current file
    Current,
    /// Delete a markdown file from the .bud directory
    Delete {
        /// Name of the file to delete (supports partial matching)
        name: String,
    },
    /// Execute a command with the current file
    Go {
        /// Prompt or command to execute
        prompt: String,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    let root_dir = find_root_dir()?;

    match cli.command {
        Commands::List => {
            let bud_dir = root_dir.join(".bud");
            list_bud_files(&bud_dir).await?;
        }
        Commands::Create { name } => {
            let bud_dir = root_dir.join(".bud");
            create_bud_file(&bud_dir, &name).await?;
        }
        Commands::Open { name } => {
            let bud_dir = root_dir.join(".bud");
            let file_name = match name {
                Some(n) => n,
                None => get_current_file(&bud_dir).await?,
            };
            open_bud_file(&bud_dir, &file_name).await?;
        }
        Commands::Switch { name } => {
            let bud_dir = root_dir.join(".bud");
            switch_current_file(&bud_dir, &name).await?;
        }
        Commands::Current => {
            let bud_dir = root_dir.join(".bud");
            let current = get_current_file(&bud_dir).await?;
            println!("Current file: {}.md", current);
        }
        Commands::Delete { name } => {
            let bud_dir = root_dir.join(".bud");
            delete_bud_file(&bud_dir, &name).await?;
        }
        Commands::Go { prompt } => {
            let bud_dir = root_dir.join(".bud");
            execute_command(&bud_dir, &prompt).await?;
        }
    }

    Ok(())
}
