#!/bin/zsh

for folder in year*
do
    pushd $folder
    echo "Running $folder:"
    source "run-fast.sh"
    popd
done

