use anyhow::{Context, Result, bail};
use std::{
    ffi::OsStr,
    path::{Path, PathBuf},
};
use tokio::fs as tokio_fs;

/// Find the git root directory by walking up the directory tree
pub fn find_root_dir() -> Result<PathBuf> {
    let current_dir = std::env::current_dir()?;
    let root_dir = current_dir
        .ancestors()
        .find(|dir| dir.join(".git").exists())
        .context("Must be called in a git repository")?;
    Ok(root_dir.to_path_buf())
}

/// Ensure the .bud directory exists
pub async fn ensure_bud_dir_exists(bud_dir: &Path) -> Result<()> {
    if !bud_dir.exists() {
        tokio_fs::create_dir_all(bud_dir).await?;
    }
    Ok(())
}

pub async fn get_current_file(bud_dir: &Path) -> Result<String> {
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
        bail!("No markdown files found in .bud directory");
    }

    // Read the current file name from CURRENT file
    let current_name = tokio_fs::read_to_string(&current_file_path).await?;
    let current_name = current_name.trim();

    // Verify the current file still exists
    let current_file_path = bud_dir.join(format!("{}.md", current_name));
    if !current_file_path.exists() {
        bail!("Current file '{}.md' no longer exists", current_name);
    }

    Ok(current_name.to_string())
}

/// Resolves a partial file name to a full file name
/// Returns the full name if unambiguous, or an error if ambiguous or not found
pub async fn resolve_file_name(bud_dir: &Path, partial_name: &str) -> Result<String> {
    let mut matching_files = Vec::new();

    let mut files = tokio_fs::read_dir(bud_dir).await?;
    while let Some(file) = files.next_entry().await? {
        let path = file.path();
        if path.is_file() && path.extension() == Some(OsStr::new("md")) {
            let file_name = path.file_name().unwrap().to_string_lossy();
            let name_without_ext = file_name.trim_end_matches(".md");

            if name_without_ext.starts_with(partial_name) {
                matching_files.push(name_without_ext.to_string());
            }
        }
    }

    match matching_files.len() {
        0 => bail!("No files found matching '{}'", partial_name),
        1 => Ok(matching_files[0].clone()),
        _ => {
            let matches = matching_files.join(", ");
            bail!(
                "Ambiguous file name '{}'. Matches: {}",
                partial_name,
                matches
            );
        }
    }
}
