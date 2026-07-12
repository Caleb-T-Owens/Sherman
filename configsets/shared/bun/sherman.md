# bun

Grabs the latest release on every apply. (The old script cleaned up the
wrong directory name on debian; fixed here.) On macOS wget comes from
brew; on the charm box it is preinstalled.

```deps
macos:macos/brew
```

```always
```

```out
$SHERMAN_DIR/bin/bun
```

```install
rm -f $SHERMAN_DIR/bin/bun

if [ $SHERMAN_PLATFORM = macos ]; then
    wget https://github.com/oven-sh/bun/releases/latest/download/bun-darwin-aarch64.zip -O bun.zip
    unzip -o bun.zip
    cp bun-darwin-aarch64/bun $SHERMAN_DIR/bin/bun
    rm bun.zip
    rm -r bun-darwin-aarch64
fi

if [ $SHERMAN_PLATFORM = debian ]; then
    wget https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64-baseline.zip -O bun.zip
    unzip -o bun.zip
    cp bun-linux-x64-baseline/bun $SHERMAN_DIR/bin/bun
    rm bun.zip
    rm -r bun-linux-x64-baseline
fi
```
