# action: apt package sync

Needs sudo; the prompt still reaches the terminal.

```deps
debian/aptfile
```

```always
```

```install
if [ $SHERMAN_ENV = anti ]; then
    cd anti
    sudo $SHERMAN_DIR/bin/aptfile sync
fi
```
