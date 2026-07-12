# aocdl — Advent of Code input downloader

Downloads once; the old install.sh had a typo ("acodl") that made it
re-download on every run.

```deps
macos/brew
```

```always
```

```out
$SHERMAN_DIR/bin/aocdl
```

```install
if [ ! -e $SHERMAN_DIR/bin/aocdl ]; then
    cd $SHERMAN_DIR/bin
    wget https://github.com/GreenLightning/advent-of-code-downloader/releases/download/v1.0.2/aocdl-macos.zip -O aocdl-macos.zip
    unzip aocdl-macos.zip
    rm aocdl-macos.zip
fi
```
