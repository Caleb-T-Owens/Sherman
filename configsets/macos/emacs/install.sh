#!/bin/bash

# Install emacs config
if [ ! -d "$HOME/.emacs.d" ]; then
    echo "Creating emacs config directory"
    mkdir -p "$HOME/.emacs.d"
fi

# Copy eshell directory if it exists
if [ -d eshell ]; then
    echo "Installing eshell config"
    cp -R eshell "$HOME/.emacs.d/"
fi

echo "Emacs configuration installed"
