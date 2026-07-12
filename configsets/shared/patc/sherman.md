# patc

Rebuilds only when the patc sources change.

```deps
shared/rustup
```

```in
$SHERMAN_DIR/projects/patc/src
$SHERMAN_DIR/projects/patc/Cargo.toml
$SHERMAN_DIR/projects/patc/Cargo.lock
```

```out
$SHERMAN_DIR/bin/patc
```

```install
cd $SHERMAN_DIR/projects/patc
cargo build --release
cp target/release/patc $SHERMAN_DIR/bin/patc
```
