# nvm / node

nvm is currently commented out of the Brewfile, so this skips gracefully
when nvm.sh is absent instead of failing every apply. Re-enable nvm in the
Brewfile and this picks it up again on the next run.

```deps
macos/brew
```

```always
```

```install
if [ ! -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
    echo "nvm is not installed via brew (not in the Brewfile); skipping"
    exit 0
fi

mkdir -p $HOME/.nvm
. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
nvm install --lts=iron
nvm alias default lts/iron
```
