#!/bin/bash

# We want to clean out the vscodium folder
echo "Removing old configs"
if [ -e $HOME/Library/Application\ Support/VSCodium/User/settings.json ]
then
    rm $HOME/Library/Application\ Support/VSCodium/User/settings.json
fi

echo "Installing new configs"
cp settings.json $HOME/Library/Application\ Support/VSCodium/User/settings.json
