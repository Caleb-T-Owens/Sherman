use crate::utils::ensure_bud_dir_exists;
use anyhow::{Result, bail};
use std::ffi::OsStr;
use std::path::Path;
use tokio::fs as tokio_fs;

pub async fn switch_current_file(bud_dir: &Path, name: &str) -> Result<()> {
    ensure_bud_dir_exists(bud_dir).await?;

    let resolved_name = resolve_file_name(bud_dir, name).await?;

    // Write the current file name to CURRENT file
    let current_file_path = bud_dir.join("CURRENT");
    tokio_fs::write(&current_file_path, &resolved_name).await?;

    println!("Switched current file to '{}.md'", resolved_name);
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
