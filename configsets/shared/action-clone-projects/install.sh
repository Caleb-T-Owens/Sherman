#!/bin/bash

# Depends on project-cloner
(cd $SHERMAN_DIR/configsets/shared/project-cloner && make)

pushd $SHERMAN_DIR/projects/project-cloner

export CLONER_PROFILE=$SHERMAN_ENV
bun run index.ts
unset CLONER_PROFILE

popd
