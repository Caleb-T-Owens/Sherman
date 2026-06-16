#!/bin/bash

# Install st
pushd $SHERMAN_DIR/buildables/st/repo

sudo make clean install

popd
