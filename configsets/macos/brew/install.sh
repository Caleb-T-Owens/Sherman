#!/bin/bash

echo "Installing new dependencies"
brew bundle --file "Brewfile" install

echo "Removing unmentioned dependencies"
brew bundle --file "Brewfile" --force cleanup
