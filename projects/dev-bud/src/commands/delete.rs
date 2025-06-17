use crate::utils::ensure_bud_dir_exists;
use anyhow::{Result, bail};
use std::ffi::OsStr;
use std::path::Path;
use tokio::fs as tokio_fs;

pub async fn delete_bud_file(bud_dir: &Path, name: &str) -> Result<()> {
    ensure_bud_dir_exists(bud_dir).await?;

    let resolved_name = resolve_file_name(bud_dir, name).await?;
    let file_path = bud_dir.join(format!("{}.md", resolved_name));

    // Check if this is the current file
    let current_file_path = bud_dir.join("CURRENT");
    let is_current = if current_file_path.exists() {
        let current_name = tokio_fs::read_to_string(&current_file_path).await?;
        current_name.trim() == resolved_name
    } else {
        false
    };

    // Delete the file
    tokio_fs::remove_file(&file_path).await?;

    // If this was the current file, clear the CURRENT file
    if is_current {
        tokio_fs::remove_file(&current_file_path).await?;
        println!(
            "Deleted '{}.md' (was current file) from .bud directory",
            resolved_name
        );
    } else {
        println!("Deleted '{}.md' from .bud directory", resolved_name);
    }

    Ok(())
}

/// Resolves a partial file name to a full file name
/// Returns the full name if unambiguous, or an error if ambiguous or not found
async fn resolve_file_name(bud_dir: &Path, partial_name: &str) -> Result<String> {
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
