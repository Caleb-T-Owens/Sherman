#!/bin/bash

# Build deploydeploy as a binary and place it in the bin folder
# This depends on bun being installed

# Remove old binary if it exists
rm -f $SHERMAN_DIR/bin/deploydeploy

# Navigate to the deploydeploy project directory
pushd $SHERMAN_DIR/projects/deploydeploy

# Build the binary using the build script
$SHERMAN_DIR/bin/bun install
$SHERMAN_DIR/bin/bun run build

# Move the binary to the Sherman bin folder
mv deploydeploy $SHERMAN_DIR/bin/deploydeploy

popd

echo "deploydeploy binary built and installed successfully"
