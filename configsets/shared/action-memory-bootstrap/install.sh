#!/bin/bash

# Ensure memory-sync binary is built and available
(cd $HOME/Sherman/configsets/shared/memory-sync && make)

# Create main memories directory if it doesn't exist
if [ ! -d $HOME/sherman_memories ]; then
    echo "Creating ~/sherman_memories directory"
    mkdir -p $HOME/sherman_memories
fi

# Remove old config if it exists
if [ -f $HOME/sherman_memories/sync-config.json ]; then
    echo "Removing old memory sync configuration"
    rm $HOME/sherman_memories/sync-config.json
fi

# Install new configuration
echo "Installing memory sync configuration"
cp sync-config.json.template $HOME/sherman_memories/sync-config.json

# Run memory sync to pull remote memories
echo "Syncing memories from remote repository..."
memory-sync sync

echo "Memory bootstrap complete"
