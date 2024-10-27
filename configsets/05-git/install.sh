#!/bin/zsh


if [ -e $HOME/.gitconfig ]
then
    echo "Removing old gitconfig"
    rm $HOME/.gitconfig
fi

if [ $SHERMAN_ENV = "work" ]
then
    cp $HOME/sherman/configsets/05-git/.gitconfig.work $HOME/.gitconfig
else
    cp $HOME/sherman/configsets/05-git/.gitconfig.home $HOME/.gitconfig
fi
