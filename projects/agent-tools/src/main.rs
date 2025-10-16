use clap::{Parser, Subcommand};

mod commands;
mod common;

#[derive(Parser)]
#[command(name = "agent-tools")]
#[command(about = "Modular toolkit for AI agent capabilities", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Web browser automation via headless Chromium
    #[command(subcommand)]
    Browse(commands::browse::BrowseCommand),
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize logging
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let cli = Cli::parse();

    match cli.command {
        Commands::Browse(cmd) => commands::browse::execute(cmd).await?,
    }

    Ok(())
}
