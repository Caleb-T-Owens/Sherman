# Neovim

On macOS neovim itself comes from brew; ripgrep is needed for telescope.

```deps
shared/ripgrep
macos:macos/brew
```

```change
copy init.lua $HOME/.config/nvim/init.lua
```
