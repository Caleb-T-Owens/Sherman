#!/bin/bash

set -euo pipefail

REPO_URL="git@github.com:learningproject/empower-learn-monorepo.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PATH="$SCRIPT_DIR/repo"

if [ ! -d "$REPO_PATH/.git" ]; then
    if [ -d "$REPO_PATH" ] && [ "$(ls -A "$REPO_PATH")" ]; then
        echo "Error: $REPO_PATH exists but is not a git repository."
        exit 1
    fi

    echo "Cloning empower-learn repository..."
    mkdir -p "$(dirname "$REPO_PATH")"
    git clone "$REPO_URL" "$REPO_PATH"
fi

echo "Fetching latest changes for empower-learn..."
git -C "$REPO_PATH" fetch origin

echo "Resetting empower-learn to origin/main..."
git -C "$REPO_PATH" reset --hard origin/main
