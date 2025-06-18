use crate::utils::ensure_bud_dir_exists;
use anyhow::Result;
use std::ffi::OsStr;
use std::path::Path;
use tokio::fs as tokio_fs;

pub async fn list_bud_files(bud_dir: &Path) -> Result<()> {
    ensure_bud_dir_exists(bud_dir).await?;

    let current_file = get_current_file(bud_dir).await.ok();

    let mut files = tokio_fs::read_dir(bud_dir).await?;
    while let Some(file) = files.next_entry().await? {
        let path = file.path();
        if path.is_file() && path.extension() == Some(OsStr::new("md")) {
            let file_name = path.file_name().unwrap().to_string_lossy();
            let name_without_ext = file_name.trim_end_matches(".md");

            if let Some(ref current) = current_file {
                if name_without_ext == current {
                    println!("* {}.md (current)", name_without_ext);
                } else {
                    println!("  {}.md", name_without_ext);
                }
            } else {
                println!("  {}.md", name_without_ext);
            }
        }
    }
    Ok(())
}

async fn get_current_file(bud_dir: &Path) -> Result<String> {
    let current_file_path = bud_dir.join("CURRENT");

    if !current_file_path.exists() {
        // If no CURRENT file exists, try to find the first .md file
        let mut files = tokio_fs::read_dir(bud_dir).await?;
        while let Some(file) = files.next_entry().await? {
            let path = file.path();
            if path.is_file() && path.extension() == Some(OsStr::new("md")) {
                let file_name = path.file_name().unwrap().to_string_lossy();
                let name_without_ext = file_name.trim_end_matches(".md");

                // Set this as the current file
                tokio_fs::write(&current_file_path, name_without_ext).await?;
                return Ok(name_without_ext.to_string());
            }
        }
        anyhow::bail!("No markdown files found in .bud directory");
    }

    // Read the current file name from CURRENT file
    let current_name = tokio_fs::read_to_string(&current_file_path).await?;
    let current_name = current_name.trim();

    // Verify the current file still exists
    let current_file_path = bud_dir.join(format!("{}.md", current_name));
    if !current_file_path.exists() {
        anyhow::bail!("Current file '{}.md' no longer exists", current_name);
    }

    Ok(current_name.to_string())
}
