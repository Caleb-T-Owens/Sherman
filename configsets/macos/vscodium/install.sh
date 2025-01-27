#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/macos/brew && make)

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/Library/Application\ Support/VSCodium/User/settings.json ]
then
    rm $HOME/Library/Application\ Support/VSCodium/User/settings.json
fi

echo "Installing new configs"
cp settings.json $HOME/Library/Application\ Support/VSCodium/User/settings.json

