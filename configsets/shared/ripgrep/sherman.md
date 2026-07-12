# ripgrep

Built from the cloned buildables repo, so we can't hash the inputs cheaply;
cargo makes the rebuild a no-op when nothing changed.

```deps
shared/rustup
shared/action-sync-buildables
```

```always
```

```out
$SHERMAN_DIR/bin/rg
```

```install
cd $SHERMAN_DIR/buildables/ripgrep/repo
cargo build --release
cp target/release/rg $SHERMAN_DIR/bin/rg
```
