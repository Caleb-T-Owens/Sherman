#!/bin/bash

# Depends on aptfile
(cd $SHERMAN_DIR/configsets/debian/aptfile && make)

if [ $SHERMAN_ENV = anti ]
then
    pushd anti
    sudo $HOME/Sherman/bin/aptfile sync
    popd
fi
