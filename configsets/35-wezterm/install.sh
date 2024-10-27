#!/bin/zsh

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.wezterm.lua ]
then
    rm $HOME/.wezterm.lua
fi

echo "Installing new configs"
cp "$HOME/sherman/configsets/35-wezterm/.wezterm.lua" "$HOME/.wezterm.lua"

