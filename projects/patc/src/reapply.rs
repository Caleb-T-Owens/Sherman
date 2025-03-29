use std::path::Path;

use crate::{
    config::Config,
    utils::{base_path, config, copy_to_workspace, get_patch_paths},
};

fn clone_project_if_required(config: &Config, base_path: &Path) {
    let clone_dir = base_path.join(".patc").join("repo");
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

fn reset_reference(config: &Config, base_path: &Path) {
    let clone_dir = base_path.join(".patc").join("repo");

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

fn apply_branch(base_path: &Path, branch_path: &std::path::Path) {
    let clone_dir = base_path.join(".patc").join("repo");

    let patch_paths = get_patch_paths(branch_path);
    for patch_path in patch_paths {
        let path_string = patch_path
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
        let path_name = patch_path.file_name().unwrap().to_str().unwrap();
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

fn apply_branches(config: &Config, base_path: &Path) {
    for branch in &config.branches {
        let branch_dir = base_path.join("branches").join(branch);

        if !branch_dir.try_exists().unwrap() {
            continue;
        }

        apply_branch(base_path, &branch_dir);
    }
}

pub fn reapply() {
    let config = config();
    let base_path = base_path();

    clone_project_if_required(&config, &base_path);
    reset_reference(&config, &base_path);
    apply_branches(&config, &base_path);
    copy_to_workspace();
}
