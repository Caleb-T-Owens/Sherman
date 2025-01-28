use std::{collections::HashMap, env, fs, path::PathBuf, process::Command};

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct ConfigEntry {
    url: String,
    profiles: Vec<String>,
}
type Config = HashMap<String, ConfigEntry>;

fn main() {
    let vars = env::vars().collect::<HashMap<_, _>>();
    let base_path: PathBuf = vars
        .get("CLONER_TARGET_DIRECTORY")
        .map(Into::into)
        .unwrap_or_else(|| env::current_dir().expect("Failed to get pwd"));
    let profile = vars
        .get("CLONER_PROFILE")
        .expect("Required CLONER_PROFILE environment variable not set");
    let cloned_path: PathBuf = base_path.join("cloned.json");

    let config = fs::read(cloned_path).expect("Failed to read config");
    let config = std::str::from_utf8(&config).expect("Config is not utf8");
    let config: Config =
        serde_json::from_str(config).expect("Config did not match expected schema");

    update_gitignore(base_path.clone(), &config);
    clone_projects(base_path, profile.clone(), &config);
}

fn update_gitignore(base_path: PathBuf, config: &Config) {
    let gitignore_path: PathBuf = base_path.join(".gitiginore");
    let gitignore = fs::read(&gitignore_path).unwrap_or_default();
    let mut gitignore = std::str::from_utf8(&gitignore)
        .expect("gitignore not utf8")
        .lines()
        .map(Into::into)
        .collect::<Vec<String>>();

    for key in config.keys() {
        let key: String = format!("{}/", key);
        if gitignore.iter().any(|entry| *entry == key) {
            gitignore.push(key);
        };
    }

    let gitignore = gitignore.join("\n");
    fs::write(gitignore_path, gitignore).expect("Failed to write gitignore")
}

fn clone_projects(base_path: PathBuf, profile: String, config: &Config) {
    for (key, value) in config {
        let project_path = base_path.join(key);
        if project_path
            .try_exists()
            .expect("Checking existance went weird.")
        {
            println!("Project {} is already cloned", key);
            continue;
        }

        if !value.profiles.iter().any(|p| *p == profile) {
            continue;
        }

        let result = Command::new("git")
            .args([
                "clone",
                &value.url,
                &project_path.into_os_string().into_string().unwrap(),
                "--recurse-submodules",
            ])
            .current_dir(&base_path)
            .spawn()
            .unwrap()
            .wait()
            .unwrap();

        if !result.success() {
            println!("Failed to clone project.")
        }
    }
}
