#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/macos/brew && make)

# Install

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.config/ghostty ]
then
    rm -r $HOME/.config/ghostty
fi

echo "Installing new configs"
cp -R ghostty/ghostty $HOME/.config/ghostty

