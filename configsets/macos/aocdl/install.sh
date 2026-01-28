#!/bin/bash

if [[ ! -e $HOME/Sherman/bin/acodl ]]
then
    # Install
    pushd $HOME/Sherman/bin

    wget https://github.com/GreenLightning/advent-of-code-downloader/releases/download/v1.0.2/aocdl-macos.zip -O aocdl-macos.zip
    unzip aocdl-macos.zip
    rm aocdl-macos.zip

    popd
fi
