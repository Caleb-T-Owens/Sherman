# deploydeploy

Built with bun from a cloned project; runs every apply.

```deps
shared/bun
```

```always
```

```out
$SHERMAN_DIR/bin/deploydeploy
```

```install
rm -f $SHERMAN_DIR/bin/deploydeploy
cd $SHERMAN_DIR/projects/deploydeploy
$SHERMAN_DIR/bin/bun install
$SHERMAN_DIR/bin/bun run build
mv deploydeploy $SHERMAN_DIR/bin/deploydeploy
echo "deploydeploy binary built and installed successfully"
```
