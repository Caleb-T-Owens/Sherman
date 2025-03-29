use crate::config::Config;

const DEFAULT_GITIGNORE: &str = "repo/
.patc/*
!.patc/.keep
";

pub fn init() {
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
