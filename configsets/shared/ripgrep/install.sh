#!/bin/bash

# Depends on rustup
(cd $SHERMAN_DIR/configsets/shared/rustup && make)

# Depends on buildables
(cd $SHERMAN_DIR/configsets/shared/action-sync-buildables && make)

# Install
pushd $SHERMAN_DIR/buildables/ripgrep/repo

cargo build --release
cp target/release/rg $SHERMAN_DIR/bin

popd
