#!/bin/bash

echo "Installing new dependencies"
brew bundle --file "Brewfile" --no-lock

echo "Removing unmentioned dependencies"
brew bundle --file "Brewfile" --force cleanup
