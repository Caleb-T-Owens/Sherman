#!/bin/bash

# Install

# We want to clean out the ghostty folder
echo "Removing old configs"
if [ -e $HOME/.config/ghostty ]
then
    rm -r $HOME/.config/ghostty
fi

echo "Installing new configs"
cp -R ghostty $HOME/.config/ghostty
