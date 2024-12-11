#!/bin/zsh

for folder in day*
do
    if [ -e $folder/setup.sh ]
    then
        pushd $folder
        echo "Running $folder setup:"
        source "setup.sh"
        popd
    fi
done
