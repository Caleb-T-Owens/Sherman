#!/bin/zsh

for folder in day*
do
    if [ -e $folder/get-input.sh ]
    then
        pushd $folder
        echo "Getting input $folder:"
        source "get-input.sh"
        popd
    fi
done
