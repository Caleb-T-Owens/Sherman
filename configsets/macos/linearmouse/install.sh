#!/bin/bash

# Install

if [ ! -d $HOME/.config/linearmouse ]
then
    echo "Creating linearmouse config directory"
    mkdir $HOME/.config/linearmouse
fi

# We want to clean out the linearmouse folder
echo "Removing old configs"
if [ -e $HOME/.config/linearmouse/linearmouse.json ]
then
    rm $HOME/.config/linearmouse/linearmouse.json
fi

echo "Installing new configs"
cp linearmouse.json $HOME/.config/linearmouse/linearmouse.json
