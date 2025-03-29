use crate::utils::{
    base_path, config, copy_to_repository, extract_patch_number, format_patch_name,
    get_patch_paths, git_reset_hard,
};

pub fn commit(message: String) {
    let config = config();
    let base_path = base_path();

    let Some(target_branch) = config.branches.last() else {
        panic!("No branches applied. Please create a branch with `patc branch create <branch name>` first");
    };

    let branch_path = base_path.join("branches").join(target_branch);

    std::fs::create_dir_all(&branch_path).expect("Failed to create branch folder");

    git_reset_hard();
    copy_to_repository();

    let repository_path = base_path.join(".patc").join("repo");

    let stdout = std::process::Command::new("git")
        .current_dir(&repository_path)
        .args(["diff", "--staged"])
        .output()
        .expect("Failed to exec git diff")
        .stdout;
    let patch = std::str::from_utf8(&stdout).expect("diff was not utf-8");

    let patch_number = get_patch_paths(&branch_path)
        .last()
        .map(|path| extract_patch_number(path.file_name().unwrap().to_str().unwrap()) + 1)
        .unwrap_or(1);

    let patch_name = format_patch_name(patch_number, &message);

    let patch_path = branch_path.join(&patch_name);
    std::fs::write(patch_path, patch).expect("Failed to write patch");

    let commit_name = format!("patc({}): {}", target_branch, patch_name);

    std::process::Command::new("git")
        .current_dir(&repository_path)
        .args(["commit", "-am", &commit_name])
        .spawn()
        .expect("Failed to spawn git commit")
        .wait()
        .expect("Commit failed");
}
