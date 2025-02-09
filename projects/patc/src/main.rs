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
.patc/*
!.patc/.keep
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
    std::fs::create_dir(pwd.join(".patc")).expect("Failed to create branches folder");
    std::fs::write(pwd.join(".patc").join(".keep"), "").expect("Failed to create branches/.keep");

    println!("Initialized patc")
}

fn clone_project_if_required(config: &Config) {
    let pwd = std::env::current_dir().expect("Failed to get pwd");
    let clone_dir = pwd.join(".patc").join("repo");
    if clone_dir
        .try_exists()
        .expect("Failed to get status of .patc/repo")
    {
        println!("Project already cloned");
        return;
    }

    let clone_dir_string = clone_dir
        .into_os_string()
        .into_string()
        .expect("Path was not utf-8");

    println!("Cloning {}", &config.repository.url);

    std::process::Command::new("git")
        .args(["clone", &config.repository.url, &clone_dir_string])
        .spawn()
        .expect("Failed to spawn git clone")
        .wait()
        .expect("Clone failed");

    println!("Clone successful");
}

fn reset_reference(config: &Config) {
    let pwd = std::env::current_dir().expect("Failed to get pwd");
    let clone_dir = pwd.join(".patc").join("repo");

    println!("Fetching latest changes");

    std::process::Command::new("git")
        .current_dir(&clone_dir)
        .args(["fetch"])
        .spawn()
        .expect("Failed to spawn git fetch")
        .wait()
        .expect("Fetch failed");

    println!("Fetch successful");
    println!("Resetting to refrence");

    std::process::Command::new("git")
        .current_dir(&clone_dir)
        .args(["reset", "--hard", &config.repository.revision])
        .spawn()
        .expect("Failed to spawn git reset")
        .wait()
        .expect("Reset failed");

    println!("Reset successful");
}

fn apply_branch(config: &Config, branch_path: &std::path::Path) {
    let pwd = std::env::current_dir().expect("Failed to get pwd");
    let clone_dir = pwd.join(".patc").join("repo");

    let branch_contents = std::fs::read_dir(branch_path).expect("Failed to read branch");
    for file in branch_contents {
        let file = file.expect("Failed to read file");
        let path = file.path();
        if !path.is_file() {
            continue;
        }
        let path_string = path
            .clone()
            .into_os_string()
            .into_string()
            .expect("Patch path was not utf-8");

        std::process::Command::new("git")
            .current_dir(&clone_dir)
            .args(["apply", "--index", &path_string])
            .spawn()
            .expect("Failed to spawn git apply")
            .wait()
            .expect("Apply failed");

        let branch_name = branch_path.file_name().unwrap().to_str().unwrap();
        let path_name = path.file_name().unwrap().to_str().unwrap();
        let commit_name = format!("patc({}): {}", branch_name, path_name);

        std::process::Command::new("git")
            .current_dir(&clone_dir)
            .args(["commit", "-am", &commit_name])
            .spawn()
            .expect("Failed to spawn git commit")
            .wait()
            .expect("Commit failed");
    }
}

fn apply_branches(config: &Config) {
    let pwd = std::env::current_dir().expect("Failed to get pwd");

    for branch in dbg!(&config.branches) {
        let branch_dir = pwd.join("branches").join(branch);

        apply_branch(config, &branch_dir);
    }
}

fn reapply() {
    let pwd = std::env::current_dir().expect("Failed to get pwd");
    let config_string =
        std::fs::read_to_string(pwd.join("patc.json")).expect("Failed to read patc.json");
    let config: Config = serde_json::from_str(&config_string).expect("Failed to parse patc.json");

    clone_project_if_required(&config);
    reset_reference(&config);
    apply_branches(&config);
}
