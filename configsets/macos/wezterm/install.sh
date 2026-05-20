#!/bin/bash

# We want to clean out the wezterm config
echo "Removing old configs"
if [ -e $HOME/.wezterm.lua ]
then
    rm $HOME/.wezterm.lua
fi

echo "Installing new configs"
cp .wezterm.lua $HOME/.wezterm.lua
