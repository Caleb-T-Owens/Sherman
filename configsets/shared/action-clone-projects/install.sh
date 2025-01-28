#!/bin/bash

# Depends on project-cloner
(cd $SHERMAN_DIR/configsets/shared/project-cloner2 && make)

pushd $SHERMAN_DIR/projects

export CLONER_PROFILE=$SHERMAN_ENV
project-cloner2
unset CLONER_PROFILE

popd
