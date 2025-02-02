#!/bin/bash

# Depends on apt packages
(cd $SHERMAN_DIR/configsets/shared/rustup && make)

# Install
rm $HOME/.bashrc
cp .bashrc $HOME/.bashrc
