use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub remote_repo: String,
    pub workspace_path: PathBuf,
    pub main_memories_path: PathBuf,
    pub sherman_root: PathBuf,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_commit_message: Option<String>,
}

impl Config {
    pub fn load() -> Result<Self> {
        let config_path = Self::config_file_path()?;

        if !config_path.exists() {
            return Self::create_default(&config_path);
        }

        let content = fs::read_to_string(&config_path)
            .context("Failed to read config file")?;

        let mut config: Config = serde_json::from_str(&content)
            .context("Failed to parse config file")?;

        // Expand paths
        config.workspace_path = expand_path(&config.workspace_path);
        config.main_memories_path = expand_path(&config.main_memories_path);
        config.sherman_root = expand_path(&config.sherman_root);

        Ok(config)
    }

    fn config_file_path() -> Result<PathBuf> {
        let home = home::home_dir()
            .context("Could not determine home directory")?;
        Ok(home.join("sherman_memories").join("sync-config.json"))
    }

    fn create_default(config_path: &Path) -> Result<Self> {
        let home = home::home_dir()
            .context("Could not determine home directory")?;

        let config = Config {
            remote_repo: "git@github.com:Caleb-T-Owens/thx-fr-th-mmrs.git".to_string(),
            workspace_path: home.join(".memory-sync-workspace"),
            main_memories_path: home.join("sherman_memories"),
            sherman_root: home.join("Sherman"),
            auto_commit_message: Some("Memory sync from {hostname} at {timestamp}".to_string()),
        };

        // Create the directory if it doesn't exist
        if let Some(parent) = config_path.parent() {
            fs::create_dir_all(parent)
                .context("Failed to create config directory")?;
        }

        let content = serde_json::to_string_pretty(&config)
            .context("Failed to serialize config")?;

        fs::write(config_path, content)
            .context("Failed to write default config")?;

        println!("Created default config at: {}", config_path.display());
        println!("You can edit this file to customize the configuration.");

        Ok(config)
    }
}

fn expand_path(path: &Path) -> PathBuf {
    if let Ok(stripped) = path.strip_prefix("~") {
        if let Some(home) = home::home_dir() {
            return home.join(stripped);
        }
    }
    path.to_path_buf()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_expand_path() {
        let path = PathBuf::from("~/test/path");
        let expanded = expand_path(&path);
        assert!(!expanded.starts_with("~"));
    }
}
