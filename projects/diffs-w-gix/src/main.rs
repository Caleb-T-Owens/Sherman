fn main() {
    // Open containing repo with an in-memory object database.
    let repo = gix::open("./example_repo").unwrap().with_object_memory();
    let empty_tree = gix::ObjectId::empty_tree(gix::hash::Kind::Sha1);
    let merge_labels = gix::merge::blob::builtin_driver::text::Labels {
        ancestor: Some("base".into()),
        current: Some("ours".into()),
        other: Some("theirs".into()),
    };

    // Create base blob & tree
    let base = repo.write_blob("a\nb\nc".as_bytes()).unwrap();
    let mut base_t_editor = repo.edit_tree(empty_tree).unwrap();
    base_t_editor
        .upsert("a_file", gix::objs::tree::EntryKind::Blob, base)
        .unwrap();
    let base_t = base_t_editor.write().unwrap();

    // Create ours blob & tree
    let ours = repo.write_blob("a\nb - foo\nc".as_bytes()).unwrap();
    let mut ours_t_editor = repo.edit_tree(empty_tree).unwrap();
    ours_t_editor
        .upsert("a_file", gix::objs::tree::EntryKind::Blob, ours)
        .unwrap();
    let ours_t = ours_t_editor.write().unwrap();

    // Create theirs blob & tree
    let theirs = repo.write_blob("a\nb\nc - foobar".as_bytes()).unwrap();
    let mut theirs_t_editor = repo.edit_tree(empty_tree).unwrap();
    theirs_t_editor
        .upsert("a_file", gix::objs::tree::EntryKind::Blob, theirs)
        .unwrap();
    let theirs_t = theirs_t_editor.write().unwrap();

    // Perform merge on the trees
    let mut output = repo
        .merge_trees(
            base_t,
            ours_t,
            theirs_t,
            merge_labels,
            gix::merge::tree::Options::default(),
        )
        .unwrap();

    let out_t = output.tree.write().unwrap();

    // Read blob from the output tree
    let blob = repo
        .find_tree(out_t)
        .unwrap()
        .lookup_entry_by_path("a_file")
        .unwrap()
        .unwrap()
        .object()
        .unwrap();

    let blob_str = str::from_utf8(&blob.data).unwrap();
    println!("Outcome:\n{}", blob_str)
}
