# project-cloner2

Rebuilds only when the cloner sources change.

```deps
shared/rustup
```

```in
$SHERMAN_DIR/projects/project-cloner2/src
$SHERMAN_DIR/projects/project-cloner2/Cargo.toml
$SHERMAN_DIR/projects/project-cloner2/Cargo.lock
```

```out
$SHERMAN_DIR/bin/project-cloner2
```

```install
cd $SHERMAN_DIR/projects/project-cloner2
cargo build --release
cp target/release/project-cloner2 $SHERMAN_DIR/bin/project-cloner2
```
