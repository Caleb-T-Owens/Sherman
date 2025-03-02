#!/bin/bash

# Depends on rustup
(cd $SHERMAN_DIR/configsets/shared/rustup && make)

# Compile patc
(cd $SHERMAN_DIR/projects/patc && make)
(cp $SHERMAN_DIR/projects/patc/target/release/patc $SHERMAN_DIR/bin/patc)

