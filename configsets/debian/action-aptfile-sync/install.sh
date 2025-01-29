#!/bin/bash

# Depends on aptfile
(cd $SHERMAN_DIR/configsets/debian/aptfile && make)

if [ $SHERMAN_ENV = anti ]
then
    pushd anti
    aptfile sync
    popd
fi