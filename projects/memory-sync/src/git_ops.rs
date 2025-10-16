use anyhow::{Context, Result, anyhow};
use git2::{Repository, Signature, IndexAddOption, Oid, Cred, RemoteCallbacks, FetchOptions};

use crate::config::Config;

fn get_ssh_callbacks<'a>() -> RemoteCallbacks<'a> {
    let mut callbacks = RemoteCallbacks::new();
    callbacks.credentials(|_url, username_from_url, _allowed_types| {
        Cred::ssh_key_from_agent(username_from_url.unwrap_or("git"))
    });
    callbacks
}

pub fn get_default_branch(repo: &Repository) -> Result<String> {
    // Try to get the current branch
    if let Ok(head) = repo.head() {
        if let Some(name) = head.shorthand() {
            return Ok(name.to_string());
        }
    }

    // Fallback to common default branches
    for branch_name in &["main", "master"] {
        let ref_name = format!("refs/heads/{}", branch_name);
        if repo.find_reference(&ref_name).is_ok() {
            return Ok(branch_name.to_string());
        }
    }

    Ok("main".to_string())
}

pub fn init_workspace(config: &Config) -> Result<()> {
    let workspace = &config.workspace_path;

    if workspace.exists() {
        println!("Workspace already exists at {}", workspace.display());

        // Check if it's a valid git repo
        match Repository::open(workspace) {
            Ok(_) => {
                println!("Existing workspace is a valid git repository");
                return Ok(());
            }
            Err(_) => {
                return Err(anyhow!(
                    "Workspace exists but is not a git repository. Please remove it manually: {}",
                    workspace.display()
                ));
            }
        }
    }

    println!("Cloning {} to {}...", config.remote_repo, workspace.display());

    let mut fetch_options = FetchOptions::new();
    fetch_options.remote_callbacks(get_ssh_callbacks());

    let mut builder = git2::build::RepoBuilder::new();
    builder.fetch_options(fetch_options);

    builder.clone(&config.remote_repo, workspace)
        .context("Failed to clone repository")?;

    println!("Repository cloned successfully");
    Ok(())
}

pub fn ensure_workspace(config: &Config) -> Result<Repository> {
    let workspace = &config.workspace_path;

    if !workspace.exists() {
        init_workspace(config)?;
    }

    Repository::open(workspace)
        .context("Failed to open workspace repository")
}

pub fn commit_changes(repo: &Repository, message: &str) -> Result<Option<Oid>> {
    let mut index = repo.index()
        .context("Failed to get repository index")?;

    // Add all changes
    index.add_all(["*"].iter(), IndexAddOption::DEFAULT, None)
        .context("Failed to add files to index")?;

    index.write()
        .context("Failed to write index")?;

    let tree_id = index.write_tree()
        .context("Failed to write tree")?;

    let tree = repo.find_tree(tree_id)
        .context("Failed to find tree")?;

    // Check if there are any changes
    let head = repo.head().ok();
    let parent_commit = head.as_ref().and_then(|h| h.peel_to_commit().ok());

    // If we have a parent commit, check if the tree is different
    if let Some(parent) = &parent_commit {
        if parent.tree()?.id() == tree.id() {
            println!("No changes to commit");
            return Ok(None);
        }
    }

    let signature = get_signature()?;

    let commit_id = if let Some(parent) = parent_commit {
        repo.commit(
            Some("HEAD"),
            &signature,
            &signature,
            message,
            &tree,
            &[&parent],
        )
    } else {
        // Initial commit
        repo.commit(
            Some("HEAD"),
            &signature,
            &signature,
            message,
            &tree,
            &[],
        )
    }.context("Failed to create commit")?;

    println!("Created commit: {}", commit_id);
    Ok(Some(commit_id))
}

pub fn pull(repo: &Repository) -> Result<bool> {
    // Fetch from origin
    let mut remote = repo.find_remote("origin")
        .context("Failed to find remote 'origin'")?;

    // Determine the default branch
    let branch_name = get_default_branch(repo)?;

    println!("Fetching from remote (branch: {})...", branch_name);

    let mut fetch_options = FetchOptions::new();
    fetch_options.remote_callbacks(get_ssh_callbacks());

    remote.fetch(&[&branch_name], Some(&mut fetch_options), None)
        .context("Failed to fetch from remote")?;

    // Get the remote branch directly instead of FETCH_HEAD
    let remote_ref = format!("refs/remotes/origin/{}", branch_name);
    let fetch_commit = match repo.find_reference(&remote_ref) {
        Ok(reference) => reference.peel_to_commit()
            .context("Failed to peel remote reference to commit")?,
        Err(_) => {
            println!("Remote branch not found, nothing to pull");
            return Ok(false);
        }
    };

    let head = repo.head()
        .context("Failed to get HEAD")?;

    let local_commit = head.peel_to_commit()
        .context("Failed to peel HEAD to commit")?;

    // Perform merge analysis
    let annotated_commit = repo.find_annotated_commit(fetch_commit.id())
        .context("Failed to create annotated commit")?;

    let (analysis, _) = repo.merge_analysis(&[&annotated_commit])
        .context("Failed to analyze merge")?;

    if analysis.is_up_to_date() {
        println!("Already up to date");
        return Ok(false);
    }

    if analysis.is_fast_forward() {
        println!("Fast-forwarding...");
        fast_forward(repo, &fetch_commit)?;
        return Ok(true);
    }

    if analysis.is_normal() {
        println!("Performing merge...");
        return normal_merge(repo, &local_commit, &fetch_commit);
    }

    Err(anyhow!("Cannot merge - unknown analysis result"))
}

fn fast_forward(repo: &Repository, target_commit: &git2::Commit) -> Result<()> {
    let mut reference = repo.head()
        .context("Failed to get HEAD")?;

    reference.set_target(target_commit.id(), "Fast-forward")
        .context("Failed to set HEAD target")?;

    repo.checkout_head(Some(git2::build::CheckoutBuilder::default().force()))
        .context("Failed to checkout HEAD")?;

    Ok(())
}

fn normal_merge(
    repo: &Repository,
    local_commit: &git2::Commit,
    remote_commit: &git2::Commit,
) -> Result<bool> {
    let local_tree = local_commit.tree()
        .context("Failed to get local tree")?;

    let remote_tree = remote_commit.tree()
        .context("Failed to get remote tree")?;

    let ancestor = repo.find_commit(
        repo.merge_base(local_commit.id(), remote_commit.id())
            .context("Failed to find merge base")?
    ).context("Failed to find ancestor commit")?;

    let ancestor_tree = ancestor.tree()
        .context("Failed to get ancestor tree")?;

    let mut index = repo.merge_trees(&ancestor_tree, &local_tree, &remote_tree, None)
        .context("Failed to merge trees")?;

    if index.has_conflicts() {
        // Write the conflicted index to the repository and working tree
        repo.index()
            .context("Failed to get repo index")?
            .read_tree(&local_tree)
            .context("Failed to read local tree into index")?;

        let mut repo_index = repo.index()
            .context("Failed to get repo index")?;

        // Merge the index with conflicts
        repo_index.read_tree(&local_tree)
            .context("Failed to read tree")?;

        // Actually, let's use git's checkout with conflicts enabled
        repo.checkout_index(Some(&mut index), Some(
            git2::build::CheckoutBuilder::default()
                .allow_conflicts(true)
                .conflict_style_merge(true)
                .force()
        )).context("Failed to checkout conflicted files")?;

        println!("⚠ Conflicts detected during merge!");
        println!();
        println!("Conflicting files:");

        // List all conflicted files
        let conflicts: Vec<_> = index.conflicts()
            .context("Failed to get conflicts")?
            .filter_map(|conflict| conflict.ok())
            .filter_map(|conflict| {
                conflict.our.or(conflict.their).map(|entry| {
                    String::from_utf8_lossy(&entry.path).to_string()
                })
            })
            .collect();

        for file in &conflicts {
            println!("  - {}", file);
        }

        println!();
        println!("The conflicted files have been written to the working tree with conflict markers.");
        println!();
        println!("To resolve:");
        println!("  1. cd {}", repo.path().parent().unwrap().display());
        println!("  2. Edit the conflicted files and remove conflict markers");
        println!("  3. git add <resolved-files>");
        println!("  4. git commit");
        println!("  5. Run memory-sync sync again");
        println!();

        return Err(anyhow!("Merge conflicts in {} file(s)", conflicts.len()));
    }

    let tree_id = index.write_tree_to(repo)
        .context("Failed to write merged tree")?;

    let tree = repo.find_tree(tree_id)
        .context("Failed to find merged tree")?;

    let signature = get_signature()?;

    repo.commit(
        Some("HEAD"),
        &signature,
        &signature,
        &format!("Merge remote changes from {}", remote_commit.id()),
        &tree,
        &[local_commit, remote_commit],
    ).context("Failed to create merge commit")?;

    repo.checkout_head(Some(git2::build::CheckoutBuilder::default().force()))
        .context("Failed to checkout merged HEAD")?;

    println!("Merge successful");
    Ok(true)
}

pub fn push(repo: &Repository) -> Result<()> {
    let mut remote = repo.find_remote("origin")
        .context("Failed to find remote 'origin'")?;

    let branch_name = get_default_branch(repo)?;

    println!("Pushing to remote (branch: {})...", branch_name);

    let refspec = format!("refs/heads/{}:refs/heads/{}", branch_name, branch_name);

    let mut push_options = git2::PushOptions::new();
    push_options.remote_callbacks(get_ssh_callbacks());

    remote.push(&[&refspec], Some(&mut push_options))
        .context("Failed to push to remote")?;

    println!("Push successful");
    Ok(())
}

fn get_signature() -> Result<Signature<'static>> {
    let hostname = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .unwrap_or_else(|| "unknown".to_string());

    Signature::now("Sherman Memory Sync", &format!("sherman@{}", hostname))
        .context("Failed to create git signature")
}
