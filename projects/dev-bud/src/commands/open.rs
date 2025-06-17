use crate::utils::{ensure_bud_dir_exists, resolve_file_name};
use anyhow::{Context, Result, bail};
use std::path::Path;
use std::process::Command;

pub async fn open_bud_file(bud_dir: &Path, name: &str) -> Result<()> {
    ensure_bud_dir_exists(bud_dir).await?;

    let resolved_name = resolve_file_name(bud_dir, name).await?;
    let file_path = bud_dir.join(format!("{}.md", resolved_name));

    let status = Command::new("cursor").arg(file_path).status().context(
        "Failed to execute 'cursor' command. Make sure Cursor is installed and available in PATH",
    )?;

    if !status.success() {
        bail!("Failed to open file in Cursor (exit code: {})", status);
    }

    println!("Opened '{}.md' in Cursor", resolved_name);
    Ok(())
}
