#!/bin/zsh


if [ ! -d "$HOME/.config/linearmouse" ]
then
    echo "Creating linearmouse config directory"
    mkdir "$HOME/.config/linearmouse"
fi

# We want to clean out the alacritty folder
echo "Removing old configs"
if [ -e $HOME/.config/linearmouse/linearmouse.json ]
then
    rm $HOME/.config/linearmouse/linearmouse.json
fi

echo "Installing new configs"
cp "$HOME/sherman/configsets/20-linearmouse/linearmouse.json" "$HOME/.config/linearmouse/linearmouse.json"
