#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_SRC_DIR="$SCRIPT_DIR/plugins/src"
CONFIG_SRC_DIR="$SCRIPT_DIR/.pi/agent"
CONFIG_DST_DIR="$HOME/.pi/agent"

echo "Installing pi configuration..."

AUTH_BACKUP=""
if [ -f "$CONFIG_DST_DIR/auth.json" ]; then
    AUTH_BACKUP="$(mktemp)"
    cp "$CONFIG_DST_DIR/auth.json" "$AUTH_BACKUP"
fi

echo "Removing old configs"
if [ -e "$CONFIG_DST_DIR" ]; then
    rm -r "$CONFIG_DST_DIR"
fi

echo "Installing new configs"
mkdir -p "$HOME/.pi"
cp -R "$CONFIG_SRC_DIR" "$CONFIG_DST_DIR"

if [ -d "$PLUGIN_SRC_DIR" ]; then
    echo "Installing source extensions"
    rm -rf "$CONFIG_DST_DIR/extensions"
    mkdir -p "$CONFIG_DST_DIR/extensions"
    cp -R "$PLUGIN_SRC_DIR"/. "$CONFIG_DST_DIR/extensions/"
fi

if [ -n "$AUTH_BACKUP" ]; then
    echo "Restoring local auth credentials"
    cp "$AUTH_BACKUP" "$CONFIG_DST_DIR/auth.json"
    rm "$AUTH_BACKUP"
fi

echo "pi configuration installed successfully!"
