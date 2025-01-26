#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/brew && make)

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/Library/Application\ Support/VSCodium/User/settings.json ]
then
    rm $HOME/Library/Application\ Support/VSCodium/User/settings.json
fi

echo "Installing new configs"
cp $HOME/sherman/configsets/vscodium/settings.json $HOME/Library/Application\ Support/VSCodium/User/settings.json

