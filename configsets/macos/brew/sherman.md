# Homebrew packages

`brew bundle` is already declarative: remove a line from the Brewfile,
re-apply, and the package is cleaned up. Runs on every apply.

```always
```

```in
Brewfile
```

```install
echo "Installing new dependencies"
brew bundle --file Brewfile install

echo "Removing unmentioned dependencies"
brew bundle --file Brewfile --force cleanup
```
