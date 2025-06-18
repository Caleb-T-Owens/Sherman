use crate::utils::ensure_bud_dir_exists;
use anyhow::Result;
use std::path::Path;
use tokio::fs as tokio_fs;

const DEFAULT_FILE_CONTENT: &str = "# Requirements

- ... fill in bullet points ...

# What this usually looks like

# What I plan on changing

# How I plan on changing it
";

pub async fn create_bud_file(bud_dir: &Path, name: &str) -> Result<()> {
    ensure_bud_dir_exists(bud_dir).await?;

    let file_path = bud_dir.join(format!("{}.md", name));
    tokio_fs::write(&file_path, DEFAULT_FILE_CONTENT).await?;

    // Set the newly created file as current
    let current_file_path = bud_dir.join("CURRENT");
    tokio_fs::write(&current_file_path, name).await?;

    println!("Created '{}.md' and set as current", name);
    Ok(())
}
