#!/bin/bash

# Depends on project-cloner
(cd $SHERMAN_DIR/configsets/shared/project-cloner2 && make)

pushd $SHERMAN_DIR/buildables

export CLONER_PROFILE=$SHERMAN_ENV
project-cloner2
unset CLONER_PROFILE

for folder in */; do
    pushd $folder

    if [ -e patc.json ]; then
        patc reapply
    fi

    popd
done

popd
