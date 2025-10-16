#!/usr/bin/env bash

# Source Sherman environment variables
source $HOME/Sherman/bin/utils/base.sh

echo "Installing Claude Code configuration..."

# Check if ~/.claude directory exists
if [ ! -d "$HOME/.claude" ]; then
    echo "~/.claude directory does not exist. Skipping installation."
    echo "Create ~/.claude directory first if you want to install Claude Code configuration."
    exit 0
fi

# Remove old CLAUDE.md if it exists
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    echo "Removing old CLAUDE.md..."
    rm "$HOME/.claude/CLAUDE.md"
fi

# Copy CLAUDE.md to ~/.claude/
echo "Copying CLAUDE.md to ~/.claude/..."
cp "CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "Claude Code configuration installed successfully!"
echo "CLAUDE.md is now available at: $HOME/.claude/CLAUDE.md"
