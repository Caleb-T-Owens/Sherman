#!/bin/bash

if [ -e $HOME/.gitconfig ]
then
    echo "Removing old gitconfig"
    rm $HOME/.gitconfig
fi

if [ $SHERMAN_ENV = work ]
then
    cp .gitconfig.work $HOME/.gitconfig
else
    cp .gitconfig.home $HOME/.gitconfig
fi
