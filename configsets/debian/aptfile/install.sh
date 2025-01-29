#!/bin/bash

# Depends on rustup
(cd $SHERMAN_DIR/configsets/shared/rustup && make)

# Install project cloner
(cd $SHERMAN_DIR/projects/aptfile && make install)