#!/bin/zsh
set -eu -o pipefail

if [ -e $HOME/.zshrc ]
then
    echo "Removing old zshrc"
    rm $HOME/.zshrc
fi

cp $HOME/sherman/configsets/95-zsh/.zshrc $HOME/.zshrc
