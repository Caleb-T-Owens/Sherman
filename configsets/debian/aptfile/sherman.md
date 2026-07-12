# aptfile — Brewfiles for apt

Rebuilds only when the aptfile sources change.

```deps
shared/rustup
```

```in
$SHERMAN_DIR/projects/aptfile/src
$SHERMAN_DIR/projects/aptfile/Cargo.toml
$SHERMAN_DIR/projects/aptfile/Cargo.lock
```

```out
$SHERMAN_DIR/bin/aptfile
```

```install
cd $SHERMAN_DIR/projects/aptfile
cargo build --release
cp target/release/aptfile $SHERMAN_DIR/bin/aptfile
```
