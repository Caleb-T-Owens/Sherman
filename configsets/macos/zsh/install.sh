#!/bin/bash

if [ -e $HOME/.zshrc ]
then
    echo "Removing old zshrc"
    rm $HOME/.zshrc
fi

cp .zshrc $HOME/.zshrc
