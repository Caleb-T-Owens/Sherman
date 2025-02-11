use crate::utils::{base_path, copy_to_repository, git_reset_hard};

pub fn diff() {
    let base_path = base_path();
    let repo_path = base_path.join(".patc").join("repo");

    git_reset_hard();

    copy_to_repository();

    std::process::Command::new("git")
        .current_dir(&repo_path)
        .args(["diff"])
        .spawn()
        .expect("Failed to spawn git diff")
        .wait()
        .expect("git diff failed");
}
