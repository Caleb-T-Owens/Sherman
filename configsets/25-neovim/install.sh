#!/bin/zsh


if [ ! -d "$HOME/.config/nvim" ]
then
    echo "Creating neovim config directory"
    mkdir "$HOME/.config/nvim"
fi

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.config/nvim/init.lua ]
then
    rm $HOME/.config/nvim/init.lua
fi

echo "Installing new configs"
cp "$HOME/sherman/configsets/25-neovim/init.lua" "$HOME/.config/nvim/init.lua"
