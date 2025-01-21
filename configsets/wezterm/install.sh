#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/brew && make)

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.wezterm.lua ]
then
    rm $HOME/.wezterm.lua
fi

echo "Installing new configs"
cp "$HOME/sherman/configsets/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"

