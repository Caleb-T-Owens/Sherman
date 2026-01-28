#!/bin/bash

pushd $SHERMAN_DIR/projects

export CLONER_PROFILE=$SHERMAN_ENV
project-cloner2
unset CLONER_PROFILE

popd
