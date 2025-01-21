#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/brew && make)

# Install

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.config/ghostty ]
then
    rm -r $HOME/.config/ghostty
fi

echo "Installing new configs"
cp -R "$HOME/sherman/configsets/ghostty/ghostty" "$HOME/.config/ghostty"

