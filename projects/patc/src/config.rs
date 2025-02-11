use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct RepositoryConfig {
    pub url: String,
    pub revision: String,
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
pub struct Config {
    pub repository: RepositoryConfig,
    pub branches: Vec<String>,
}
