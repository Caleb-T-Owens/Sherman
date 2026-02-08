use anyhow::{Context, Result};
use clap::Parser;
use gix::objs::WriteTo;
use gix::prelude::Write;
use std::process::Command;

#[derive(Parser)]
#[command(name = "two-same-parents")]
#[command(about = "Create a commit with N duplicate parent entries")]
struct Cli {
    /// Commit message
    #[arg(short, long)]
    message: String,

    /// Number of duplicate parent entries
    #[arg(short, long, default_value = "2")]
    num_parents: usize,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Open the repository
    let repo = gix::discover(".")?;

    // Get HEAD commit
    let head_commit = repo
        .head_commit()
        .context("Failed to get HEAD commit - is this a repository with commits?")?;
    let head_id = head_commit.id();

    // Get tree from index by shelling out to git write-tree
    let output = Command::new("git")
        .arg("write-tree")
        .output()
        .context("Failed to run git write-tree")?;

    if !output.status.success() {
        anyhow::bail!(
            "git write-tree failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    let tree_hex = String::from_utf8(output.stdout)
        .context("Invalid UTF-8 from git write-tree")?
        .trim()
        .to_string();

    let tree_id = gix::ObjectId::from_hex(tree_hex.as_bytes())
        .context("Failed to parse tree object ID")?;

    // Get author/committer from config
    let committer = repo.committer().context("Failed to get committer from config")??;
    let author = repo.author().context("Failed to get author from config")??;

    // Build commit with N duplicate parents
    let parent_id: gix::ObjectId = head_id.into();
    let parents: smallvec::SmallVec<[gix::ObjectId; 1]> =
        std::iter::repeat(parent_id)
            .take(cli.num_parents)
            .collect();

    let commit = gix::objs::Commit {
        tree: tree_id,
        parents,
        author: author.to_owned(),
        committer: committer.to_owned(),
        encoding: None,
        message: cli.message.clone().into(),
        extra_headers: vec![],
    };

    // Serialize and write the commit object
    let mut buf = Vec::new();
    commit.write_to(&mut buf)?;

    // Write as a commit object using the object database
    let odb = repo.objects.clone();
    let new_commit_id = odb
        .write_buf(gix::object::Kind::Commit, &buf)
        .map_err(|e| anyhow::anyhow!("Failed to write commit object: {}", e))?;

    // Update HEAD to point to the new commit
    let mut head_ref = repo.head_ref()?.context("HEAD is detached or missing")?;
    head_ref
        .set_target_id(new_commit_id, format!("commit: {}", cli.message.lines().next().unwrap_or("")))
        .context("Failed to update HEAD")?;

    println!("Created commit {} with {} duplicate parents pointing to {}",
             new_commit_id, cli.num_parents, head_id);

    Ok(())
}
