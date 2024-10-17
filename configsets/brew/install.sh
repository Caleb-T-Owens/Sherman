#!/bin/zsh
set -eu -o pipefail

pushd "$HOME/sherman/configsets/brew"

echo "Installing new dependencies"
brew bundle --file "Brewfile" --no-lock

echo "Removing unmentioned dependencies"
brew bundle --file "Brewfile" --force cleanup

popd
