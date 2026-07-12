# memory-sync

Rebuilds only when the memory-sync sources change.

```deps
shared/rustup
```

```in
$SHERMAN_DIR/projects/memory-sync/src
$SHERMAN_DIR/projects/memory-sync/Cargo.toml
$SHERMAN_DIR/projects/memory-sync/Cargo.lock
```

```out
$SHERMAN_DIR/bin/memory-sync
```

```install
cd $SHERMAN_DIR/projects/memory-sync
cargo build --release
cp target/release/memory-sync $SHERMAN_DIR/bin/memory-sync
```
