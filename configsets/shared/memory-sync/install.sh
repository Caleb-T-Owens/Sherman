#!/bin/bash

# Navigate to memory-sync project and build
echo "Building memory-sync..."
pushd $HOME/Sherman/projects/memory-sync
cargo build --release
popd

# Remove old binary if exists
if [ -f $HOME/Sherman/bin/memory-sync ]; then
    rm $HOME/Sherman/bin/memory-sync
fi

# Install new binary
echo "Installing memory-sync to ~/Sherman/bin/"
cp $HOME/Sherman/projects/memory-sync/target/release/memory-sync $HOME/Sherman/bin/memory-sync
chmod +x $HOME/Sherman/bin/memory-sync

echo "memory-sync installed successfully"
