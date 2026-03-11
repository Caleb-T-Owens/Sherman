#!/bin/bash

# Install

if [ ! -d $HOME/.config/nvim ]
then
    echo "Creating neovim config directory"
    mkdir $HOME/.config/nvim
fi

# We want to clean out the nvim folder
echo "Removing old configs"
if [ -e $HOME/.config/nvim/init.lua ]
then
    rm $HOME/.config/nvim/init.lua
fi

echo "Installing new configs"
cp init.lua $HOME/.config/nvim/init.lua
