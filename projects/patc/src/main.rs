use serde::{Deserialize, Serialize};

#[derive(Debug, clap::Parser)]
#[clap(name = "patc", about = "The stupid patch tracker", version = "0.0.1")]
struct Args {
    #[clap(subcommand)]
    pub cmd: Subcommand,
}

#[derive(Debug, clap::Subcommand)]
enum Subcommand {
    Init {},
    Reapply {},
}

fn main() {
    let args: Args = clap::Parser::parse();

    match args.cmd {
        Subcommand::Init { .. } => init(),
        Subcommand::Reapply { .. } => reapply(),
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct RepositoryConfig {
    url: String,
    revision: String,
}

impl Default for RepositoryConfig {
    fn default() -> Self {
        Self {
            url: "https://example.com/foo.git".into(),
            revision: "origin/master".into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct Config {
    repository: RepositoryConfig,
    branches: Vec<String>,
}

const DEFAULT_GITIGNORE: &str = "repo/
.patc-meta
";

fn init() {
    let pwd = std::env::current_dir().expect("Failed to get pwd");
    let pwd_children_count = pwd.read_dir().expect("Failed to read pwd").count();
    if pwd_children_count != 0 {
        panic!("`patc init` should only be run in an empty directory");
    };

    let config =
        serde_json::to_string(&Config::default()).expect("Failed to serialize patc config");
    std::fs::write(pwd.join("patc.json"), config).expect("Failed to write patc.json");
    std::fs::write(pwd.join(".gitignore"), DEFAULT_GITIGNORE).expect("Failed to write .gitignore");
    std::fs::create_dir(pwd.join("branches")).expect("Failed to create branches folder");
    std::fs::write(pwd.join("branches").join(".keep"), "")
        .expect("Failed to create branches/.keep");

    println!("Initialized patc")
}

fn reapply() {
    unimplemented!()
}
