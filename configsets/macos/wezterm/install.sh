#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/macos/brew && make)

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.wezterm.lua ]
then
    rm $HOME/.wezterm.lua
fi

echo "Installing new configs"
cp .wezterm.lua $HOME/.wezterm.lua

