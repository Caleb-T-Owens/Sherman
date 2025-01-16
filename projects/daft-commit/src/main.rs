use std::env::current_dir;

use clap::Parser;
use gix::head;

// Stuff taken from gitbutler
mod gitbutler {
    pub(crate) fn to_gix(id: git2::Oid) -> gix::ObjectId {
        gix::ObjectId::try_from(id.as_bytes()).expect("git2 oid is always valid")
    }

    pub(crate) fn merge_options_fail_fast(
        repository: &gix::Repository,
    ) -> (
        gix::merge::tree::Options,
        gix::merge::tree::TreatAsUnresolved,
    ) {
        let conflict_kind = gix::merge::tree::TreatAsUnresolved::forced_resolution();
        let options = repository
            .tree_merge_options()
            .unwrap()
            .with_fail_on_conflict(Some(conflict_kind));
        (options, conflict_kind)
    }
}

use gitbutler::*;

#[derive(Parser, Debug)]
#[command(
    version = "0.1",
    name = "daft-commit",
    about = "A commit command with a bit more oomf"
)]
struct Args {
    #[arg(short, long)]
    parent: String,

    #[arg(short, long)]
    message: String,
}

fn main() {
    let args = Args::parse();

    let repository =
        gix::discover(current_dir().unwrap()).expect("Could not find a git repository");

    let parent = repository
        .rev_parse_single(args.parent.as_str())
        .expect("Failed to parse parent revision");

    let head_commit = repository.head_id().expect("Repository has no head commit");

    let commits_to_move = repository
        .rev_walk([head_commit])
        .with_pruned([parent])
        .first_parent_only()
        .sorting(gix::revision::walk::Sorting::BreadthFirst)
        .all()
        .expect("gix is perfect")
        .map(|commit| commit.unwrap())
        .collect::<Vec<_>>();

    if commits_to_move
        .iter()
        .any(|commit| commit.parent_ids.len() > 1)
    {
        panic!("Can not operate on commits with more than one parent");
    }

    let new_patch = commit_changes(&repository, args.message, parent.detach());

    for commit in commits_to_move.iter().rev() {}

    todo!();
}

fn commit_changes(
    repository: &gix::Repository,
    message: String,
    parent: gix::ObjectId,
) -> gix::ObjectId {
    // Shhh... naughty things going on here :D
    let git2_repository = git2::Repository::open(repository.path()).unwrap();

    let head_commit = repository.head_id().expect("Repository has no head commit");

    let index_tree = to_gix(git2_repository.index().unwrap().write_tree().unwrap());
    let head_tree = head_commit.object().unwrap().peel_to_tree().unwrap();
    let parent_tree = repository.find_commit(parent).unwrap().tree().unwrap();

    let (fail_fast, conflict_kind) = merge_options_fail_fast(&repository);
    let mut merge_result = repository
        .merge_trees(
            head_tree.id(),
            index_tree,
            parent_tree.id(),
            Default::default(),
            fail_fast,
        )
        .unwrap();

    if merge_result.has_unresolved_conflicts(conflict_kind) {
        panic!("Merge ending up conflicted");
    }

    let merged_tree = merge_result.tree.write().unwrap();
    let author = repository.author().unwrap().unwrap();

    let commit = gix::objs::Commit {
        tree: merged_tree.detach(),
        parents: [parent].into(),
        author: author.into(),
        committer: author.into(),
        message: message.into(),
        encoding: None,
        extra_headers: vec![],
    };

    repository.write_object(commit).unwrap().detach()
}
