#!/bin/zsh

for folder in year*
do
    pushd $folder
    echo "Running $folder setup:"
    source "setup.sh"
    popd
done
