#!/bin/zsh

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.config/ghostty ]
then
    rm -r $HOME/.config/ghostty
fi

echo "Installing new configs"
cp -R "$HOME/sherman/configsets/40-ghostty/ghostty" "$HOME/.config/ghostty"

