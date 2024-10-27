#!/bin/zsh


if [ ! -d "$HOME/.config/alacritty" ]
then
    echo "Creating alacritty config directory"
    mkdir "$HOME/.config/alacritty"
fi

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.config/alacritty/alacritty.toml ]
then
    rm $HOME/.config/alacritty/alacritty.toml
fi

echo "Installing new configs"
cp "$HOME/sherman/configsets/10-alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
