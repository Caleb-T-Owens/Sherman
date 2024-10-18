#!/bin/zsh
set -eu -o pipefail

pushd "$HOME/sherman/configsets/00-brew"

echo "Installing new dependencies"
brew bundle --file "Brewfile" --no-lock

echo "Removing unmentioned dependencies"
brew bundle --file "Brewfile" --force cleanup

# nvm post install
if [ ! -e $HOME/.nvm ]
then
    mkdir $HOME/.nvm
fi

popd
