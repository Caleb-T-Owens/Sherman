#!/bin/bash

# Install ripgrep from buildables
pushd $SHERMAN_DIR/buildables/ripgrep/repo

cargo build --release
cp target/release/rg $SHERMAN_DIR/bin

popd
