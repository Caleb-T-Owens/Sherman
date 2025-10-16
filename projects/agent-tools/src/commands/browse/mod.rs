use clap::Subcommand;

mod daemon;
mod commands;
mod workflow;
mod ollama;

#[derive(Subcommand)]
pub enum BrowseCommand {
    /// Start the browser daemon
    Daemon {
        #[command(subcommand)]
        action: DaemonAction,
    },
    /// Navigate to a URL
    Navigate {
        /// URL to navigate to
        url: String,
        /// Optional tab ID (uses current tab if not specified)
        #[arg(long)]
        tab: Option<String>,
    },
    /// Take a screenshot
    Screenshot {
        /// CSS selector to screenshot (full page if not specified)
        selector: Option<String>,
        /// Output file path
        #[arg(short, long)]
        output: Option<String>,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Click an element
    Click {
        /// CSS selector of element to click
        selector: String,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Type text into an element
    Type {
        /// CSS selector of input element
        selector: String,
        /// Text to type
        text: String,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Extract text or HTML from element(s)
    Extract {
        /// CSS selector
        selector: String,
        /// Extract HTML instead of text
        #[arg(long)]
        html: bool,
        /// Extract from all matching elements
        #[arg(long)]
        all: bool,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Execute JavaScript in the page
    Eval {
        /// JavaScript code to execute
        js: String,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Wait for an element to appear
    Wait {
        /// CSS selector to wait for
        selector: String,
        /// Timeout in seconds (default: 30)
        #[arg(short, long, default_value = "30")]
        timeout: u64,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Manage tabs
    Tabs {
        #[command(subcommand)]
        action: TabAction,
    },
    /// Save page as PDF
    Pdf {
        /// Output file path
        #[arg(short, long)]
        output: String,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Get cookies
    GetCookies {
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Set a cookie
    SetCookie {
        /// Cookie name
        name: String,
        /// Cookie value
        value: String,
        /// Cookie domain
        #[arg(short, long)]
        domain: Option<String>,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Delete cookies
    DeleteCookies {
        /// Cookie name pattern (deletes all if not specified)
        name: Option<String>,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Set user agent
    SetUserAgent {
        /// User agent string
        user_agent: String,
        /// Optional tab ID
        #[arg(long)]
        tab: Option<String>,
    },
    /// Start recording a workflow
    Record {
        /// Workflow name
        name: String,
        /// Workflow description
        #[arg(short, long)]
        description: Option<String>,
    },
    /// Stop recording and save the workflow
    StopRecord,
    /// Replay a saved workflow
    Replay {
        /// Workflow name to replay
        name: String,
    },
    /// List all saved workflows
    ListWorkflows,
    /// Delete a workflow
    DeleteWorkflow {
        /// Workflow name to delete
        name: String,
    },
    /// Suggest similar workflows for a task
    Suggest {
        /// Task description
        task: String,
        /// Number of suggestions (default: 3)
        #[arg(short, long, default_value = "3")]
        limit: usize,
    },
}

#[derive(Subcommand)]
pub enum DaemonAction {
    /// Start the daemon
    Start {
        /// Run in foreground (don't daemonize)
        #[arg(short, long)]
        foreground: bool,
        /// Show browser window (headless by default)
        #[arg(long)]
        headed: bool,
    },
    /// Stop the daemon
    Stop,
    /// Check daemon status
    Status,
}

#[derive(Subcommand)]
pub enum TabAction {
    /// List all tabs
    List,
    /// Create a new tab
    New {
        /// Optional URL to navigate to
        url: Option<String>,
    },
    /// Switch to a tab
    Switch {
        /// Tab ID to switch to
        id: String,
    },
    /// Close a tab
    Close {
        /// Tab ID to close
        id: String,
    },
}

pub async fn execute(command: BrowseCommand) -> anyhow::Result<()> {
    match command {
        BrowseCommand::Daemon { action } => daemon::handle_daemon(action).await,
        _ => commands::handle_command(command).await,
    }
}
