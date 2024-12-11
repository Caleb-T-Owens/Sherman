#!/bin/zsh

for folder in day*
do
    pushd $folder
    echo "Running $folder:"
    source "run.sh"
    popd
done
