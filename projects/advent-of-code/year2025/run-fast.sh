#!/bin/zsh

for folder in day*
do
    if [ ! -e $folder/slow ]
    then
        pushd $folder
        echo "Running $folder:"
        source "run.sh"
        popd
    fi
done
