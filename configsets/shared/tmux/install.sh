#!/bin/bash

if [ ! -d $HOME/.config/tmux ]
then
    echo "Creating tmux config directory"
    mkdir $HOME/.config/tmux
fi

echo "Removing old configs"

if [ -e $HOME/.tmux.conf ]
then
    rm $HOME/.tmux.conf
fi

echo "Installing new configs"
cp tmux.conf $HOME/.tmux.conf
