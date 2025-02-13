use crate::config::Config;

pub fn base_path() -> std::path::PathBuf {
    let pwd = std::env::current_dir().expect("Failed to get pwd");
    let mut path = pwd.to_owned();
    loop {
        if path.join("patc.json").try_exists().unwrap() {
            break;
        }

        path = path.parent().expect("Failed to find patc directory").into();
    }

    path
}

pub fn config() -> Config {
    let base_path = base_path();
    let config_string =
        std::fs::read_to_string(base_path.join("patc.json")).expect("Failed to read patc.json");
    let config: Config = serde_json::from_str(&config_string).expect("Failed to parse patc.json");
    config
}

pub fn copy_to_workspace() {
    let base_path = base_path();

    let repository_path = base_path.join(".patc").join("repo");
    let workspace_path = base_path.join("repo");
    std::fs::create_dir_all(&workspace_path).expect("Failed to create workspace path if missing");

    let contents = workspace_path
        .read_dir()
        .expect("Failed to read workspace contents")
        .map(|entry| entry.unwrap().path())
        .collect::<Vec<_>>();
    fs_extra::remove_items(&contents).expect("Failed to remove workspace contents");
    let new_contents = repository_path
        .read_dir()
        .expect("Failed to read repo contents")
        .filter_map(|entry| {
            let entry = entry.unwrap();
            if entry.file_name().into_string().unwrap() == *".git" {
                None
            } else {
                Some(entry.path())
            }
        })
        .collect::<Vec<_>>();
    fs_extra::copy_items(&new_contents, workspace_path, &Default::default())
        .expect("Failed to copy files");
}

pub fn copy_to_repository() {
    let base_path = base_path();

    let repository_path = base_path.join(".patc").join("repo");
    let workspace_path = base_path.join("repo");
    std::fs::create_dir_all(&workspace_path).expect("Failed to create workspace path if missing");
    let repository_contents_for_removal = repository_path
        .read_dir()
        .expect("Failed to read repo contents")
        .filter_map(|entry| {
            let entry = entry.unwrap();
            if entry.file_name().into_string().unwrap() == *".git" {
                None
            } else {
                Some(entry.path())
            }
        })
        .collect::<Vec<_>>();
    fs_extra::remove_items(&repository_contents_for_removal)
        .expect("Failed to clear out repository contents");

    let workspace_contents = workspace_path
        .read_dir()
        .expect("Failed to read repo contents")
        .filter_map(|entry| {
            let entry = entry.unwrap();
            if entry.file_name().into_string().unwrap() == *".git" {
                None
            } else {
                Some(entry.path())
            }
        })
        .collect::<Vec<_>>();

    fs_extra::copy_items(&workspace_contents, repository_path, &Default::default())
        .expect("Failed to copy workspace contents");
}

pub fn git_reset_hard() {
    let base_path = base_path();
    let repo_path = base_path.join(".patc").join("repo");

    std::process::Command::new("git")
        .current_dir(&repo_path)
        .args(["reset", "--hard", "--quiet"])
        .spawn()
        .expect("Failed to spawn git reset --hard")
        .wait_with_output()
        .expect("git reset failed");
}

pub fn try_extract_patch_number(file_name: &str) -> Result<u32, String> {
    let number = file_name
        .split_once('-')
        .ok_or("Failed to take patch number")?
        .0
        .parse()
        .map_err(|_| "Failed to parse patch number")?;
    Ok(number)
}

pub fn extract_patch_number(file_name: &str) -> u32 {
    try_extract_patch_number(file_name).unwrap()
}

pub fn format_patch_name(number: u32, message: &str) -> String {
    format!("{}-{}.patch", number, message)
}

pub fn get_patch_paths(branch_path: &std::path::Path) -> Vec<std::path::PathBuf> {
    match std::fs::read_dir(branch_path) {
        Err(_) => vec![],
        Ok(dir) => {
            let mut paths = vec![];
            for entry in dir {
                let entry = entry.unwrap();

                let file_name = entry
                    .file_name()
                    .into_string()
                    .expect("patch name not utf8");

                try_extract_patch_number(&file_name)
                    .expect("Patches should start with a positive decimal number, IE `23`");

                if !file_name.ends_with(".patch") {
                    panic!("Patches should end with .patch")
                }

                paths.push(entry.path().to_owned());
            }

            paths.sort_by_cached_key(|path| {
                extract_patch_number(path.file_name().unwrap().to_str().unwrap())
            });

            paths
        }
    }
}
