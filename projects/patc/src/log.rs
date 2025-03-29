use crate::utils::{base_path, config, copy_to_repository, git_reset_hard};

pub fn log() {
    let base_path = base_path();
    let repo_path = base_path.join(".patc").join("repo");
    let config = config();

    git_reset_hard();

    copy_to_repository();

    let revision = format!("{}..HEAD", config.repository.revision);

    std::process::Command::new("git")
        .current_dir(&repo_path)
        .args(["log", "--oneline", "--no-decorate", &revision])
        .spawn()
        .expect("Failed to spawn git log")
        .wait()
        .expect("git log failed");
}
