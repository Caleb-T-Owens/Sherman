#!/bin/bash

if [ -e $HOME/.sdkman ]
then
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk selfupdate
else
    # Scary install script goes brrr
    curl -s "https://get.sdkman.io" | bash
fi
