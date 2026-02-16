#!/bin/bash

# Dependency brew
(cd $HOME/Sherman/configsets/macos/brew && make)

# Install
TARGET_DIR="$HOME/Library/Application Support/espanso"

# We want to clean out the espanso folder
echo "Removing old configs"
if [ -e "$TARGET_DIR" ]
then
    rm -r "$TARGET_DIR"
fi

echo "Installing new configs"
cp -R espanso "$TARGET_DIR"

# Ensure package directory exists even when empty in repo
mkdir -p "$TARGET_DIR/match/packages"

# Ensure scripts remain executable
if [ -d "$TARGET_DIR/scripts" ]
then
    find "$TARGET_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} +
fi
