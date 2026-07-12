# espanso

The config directory is replaced on apply; the packages dir must exist even
when empty in the repo, and scripts need their exec bit.

```deps
macos/brew
```

```change
copy espanso $HOME/Library/Application Support/espanso
```

```out
$HOME/Library/Application Support/espanso/match/packages
```

```install
mkdir -p "$HOME/Library/Application Support/espanso/match/packages"
if [ -d "$HOME/Library/Application Support/espanso/scripts" ]; then
    find "$HOME/Library/Application Support/espanso/scripts" -type f -name "*.sh" -exec chmod +x {} +
fi
```
