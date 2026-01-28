#!/bin/bash

if [ $SHERMAN_ENV = anti ]
then
    pushd anti
    sudo $HOME/Sherman/bin/aptfile sync
    popd
fi
