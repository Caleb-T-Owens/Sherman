#!/bin/zsh

go install github.com/GreenLightning/advent-of-code-downloader/aocdl@latest

alias aocdl="$(go env GOPATH)/bin/aocdl"

for folder in year*
do
    pushd $folder
    echo "Getting input $folder:"
    source "get-input.sh"
    popd
done

