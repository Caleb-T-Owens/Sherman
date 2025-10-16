use anyhow::{Context, Result};
use std::fs;
use std::path::Path;
use walkdir::WalkDir;
use chrono::Local;

use crate::config::Config;
use crate::git_ops;

pub fn sync(config: &Config) -> Result<()> {
    // Full bidirectional sync with fetch-first approach
    let repo = git_ops::ensure_workspace(config)?;
    let workspace = &config.workspace_path;

    // Step 1: Pull remote changes first to avoid push conflicts
    println!("Pulling remote changes...");
    let has_remote_changes = git_ops::pull(&repo)?;

    if has_remote_changes {
        println!("Copying remote changes to local folders...");
        copy_workspace_to_local(config, workspace)?;
    }

    // Step 2: Collect local changes into workspace
    println!("Collecting local memories...");
    copy_local_to_workspace(config, workspace)?;

    // Step 3: Commit local changes
    let message = generate_commit_message(config);
    if let Some(_) = git_ops::commit_changes(&repo, &message)? {
        // Step 4: Push (should succeed since we pulled first)
        git_ops::push(&repo)?;
    } else {
        println!("No local changes to commit");
    }

    println!("✓ Sync complete");
    Ok(())
}

pub fn push(config: &Config) -> Result<()> {
    let repo = git_ops::ensure_workspace(config)?;
    let workspace = &config.workspace_path;

    println!("Collecting local memories...");
    copy_local_to_workspace(config, workspace)?;

    // Commit changes
    let message = generate_commit_message(config);
    if let Some(_commit_id) = git_ops::commit_changes(&repo, &message)? {
        // Push to remote
        git_ops::push(&repo)?;
    } else {
        println!("No changes to push");
    }

    Ok(())
}

pub fn pull(config: &Config) -> Result<()> {
    let repo = git_ops::ensure_workspace(config)?;
    let workspace = &config.workspace_path;

    println!("Pulling from remote...");

    let has_changes = git_ops::pull(&repo)?;

    if !has_changes {
        return Ok(());
    }

    println!("Copying memories back to local folders...");
    copy_workspace_to_local(config, workspace)?;

    Ok(())
}

pub fn status(config: &Config) -> Result<()> {
    let repo = git_ops::ensure_workspace(config)?;

    // Check for uncommitted changes
    let statuses = repo.statuses(None)
        .context("Failed to get repository status")?;

    if statuses.is_empty() {
        println!("✓ Workspace is clean");
    } else {
        println!("Uncommitted changes in workspace:");
        for entry in statuses.iter() {
            let status = entry.status();
            let path = entry.path().unwrap_or("unknown");

            let status_str = if status.is_wt_new() {
                "new"
            } else if status.is_wt_modified() {
                "modified"
            } else if status.is_wt_deleted() {
                "deleted"
            } else {
                "changed"
            };

            println!("  {} {}", status_str, path);
        }
    }

    // Check if we're ahead/behind remote
    let head = repo.head()
        .context("Failed to get HEAD")?;

    let local_oid = head.target()
        .context("Failed to get HEAD target")?;

    // Try to get remote tracking branch
    let branch_name = git_ops::get_default_branch(&repo)?;
    let remote_ref = format!("refs/remotes/origin/{}", branch_name);

    if let Ok(upstream) = repo.find_reference(&remote_ref) {
        let remote_oid = upstream.target()
            .context("Failed to get remote tracking branch target")?;

        if local_oid == remote_oid {
            println!("✓ In sync with remote");
        } else {
            let (ahead, behind) = repo.graph_ahead_behind(local_oid, remote_oid)
                .context("Failed to calculate ahead/behind")?;

            if ahead > 0 {
                println!("↑ {} commit(s) ahead of remote", ahead);
            }
            if behind > 0 {
                println!("↓ {} commit(s) behind remote", behind);
            }
        }
    }

    Ok(())
}

fn sync_directory(source: &Path, dest: &Path, include_dotfiles: bool) -> Result<()> {
    if !source.exists() {
        return Ok(());
    }

    fs::create_dir_all(dest)
        .context(format!("Failed to create directory: {}", dest.display()))?;

    for entry in WalkDir::new(source)
        .follow_links(false)
        .into_iter()
        .filter_entry(|e| {
            // Skip .git directories
            if e.file_name() == ".git" {
                return false;
            }
            // Skip sync-config.json
            if e.file_name() == "sync-config.json" {
                return false;
            }
            // Skip dotfiles if requested (except in subdirectories)
            if !include_dotfiles && e.depth() == 1 {
                if let Some(name) = e.file_name().to_str() {
                    if name.starts_with('.') {
                        return false;
                    }
                }
            }
            true
        })
    {
        let entry = entry?;
        let path = entry.path();

        if path == source {
            continue;
        }

        let relative_path = path.strip_prefix(source)
            .context("Failed to get relative path")?;

        let dest_path = dest.join(relative_path);

        if path.is_dir() {
            fs::create_dir_all(&dest_path)
                .context(format!("Failed to create directory: {}", dest_path.display()))?;
        } else {
            if let Some(parent) = dest_path.parent() {
                fs::create_dir_all(parent)
                    .context(format!("Failed to create parent directory: {}", parent.display()))?;
            }
            fs::copy(path, &dest_path)
                .context(format!("Failed to copy {} to {}", path.display(), dest_path.display()))?;
        }
    }

    Ok(())
}

fn copy_local_to_workspace(config: &Config, workspace: &Path) -> Result<()> {
    // Sync main memories
    let main_dest = workspace.join("main");
    sync_directory(&config.main_memories_path, &main_dest, true)?;

    // Sync project memories
    let projects_dir = config.sherman_root.join("projects");
    if projects_dir.exists() {
        for entry in fs::read_dir(&projects_dir)? {
            let entry = entry?;
            let path = entry.path();

            if path.is_dir() {
                let memories_path = path.join(".agents").join("memories");
                if memories_path.exists() {
                    let project_name = path.file_name()
                        .and_then(|n| n.to_str())
                        .unwrap_or("unknown");

                    let dest = workspace.join("projects").join(project_name);
                    sync_directory(&memories_path, &dest, false)?;
                    println!("  Synced project: {}", project_name);
                }
            }
        }
    }

    Ok(())
}

fn copy_workspace_to_local(config: &Config, workspace: &Path) -> Result<()> {
    // Restore main memories
    let main_source = workspace.join("main");
    if main_source.exists() {
        sync_directory(&main_source, &config.main_memories_path, true)?;
    }

    // Restore project memories
    let projects_source = workspace.join("projects");
    if projects_source.exists() {
        for entry in fs::read_dir(&projects_source)? {
            let entry = entry?;
            let source_path = entry.path();

            if source_path.is_dir() {
                let project_name = source_path.file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("unknown");

                let project_dir = config.sherman_root.join("projects").join(project_name);
                if project_dir.exists() {
                    let dest = project_dir.join(".agents").join("memories");
                    sync_directory(&source_path, &dest, false)?;
                    println!("  Restored project: {}", project_name);
                } else {
                    println!("  ⚠ Project '{}' not found locally, skipping", project_name);
                }
            }
        }
    }

    Ok(())
}

fn generate_commit_message(config: &Config) -> String {
    let template = config.auto_commit_message
        .as_deref()
        .unwrap_or("Memory sync from {hostname} at {timestamp}");

    let hostname = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .unwrap_or_else(|| "unknown".to_string());

    let timestamp = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();

    template
        .replace("{hostname}", &hostname)
        .replace("{timestamp}", &timestamp)
}
