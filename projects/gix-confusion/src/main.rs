use gix::merge::tree::TreatAsUnresolved;

fn main() {
    let tmp_dir = tempdir::TempDir::new("foo").unwrap();
    let repo = gix::init(tmp_dir.path()).unwrap();

    // Tree 1
    let mut editor = repo
        .edit_tree(gix::ObjectId::empty_tree(gix::hash::Kind::Sha1))
        .unwrap();
    let blob = repo.write_blob("I'm a file\n\nYay!").unwrap();
    editor
        .upsert("foobar", gix::objs::tree::EntryKind::Blob, blob)
        .unwrap();
    let ours = editor.write().unwrap();

    // Tree 2
    let mut editor = repo
        .edit_tree(gix::ObjectId::empty_tree(gix::hash::Kind::Sha1))
        .unwrap();
    let blob = repo.write_blob("I'm a file\n\nasdf\n\nYay!").unwrap();
    editor
        .upsert("foobar", gix::objs::tree::EntryKind::Blob, blob)
        .unwrap();
    let theirs = editor.write().unwrap();

    let conflict_kind = TreatAsUnresolved::forced_resolution();
    let options = repo
        .tree_merge_options()
        .unwrap()
        .with_fail_on_conflict(Some(conflict_kind))
        .with_rewrites(None);

    let merge_outcome = repo
        .merge_trees(
            gix::ObjectId::empty_tree(gix::hash::Kind::Sha1),
            ours,
            theirs,
            Default::default(),
            options,
        )
        .unwrap();
    // This should be true
    dbg!(merge_outcome.has_unresolved_conflicts(conflict_kind));
}
