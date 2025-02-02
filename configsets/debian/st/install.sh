#!/bin/bash

# Depends on action-aptfile-sync
(cd $SHERMAN_DIR/configsets/debian/action-aptfile-sync && make)

# Install st
pushd $SHERMAN_DIR/buildables/st/repo

sudo make install

popd
