#!/bin/bash

if [ ! -e $HOME/.sdkman ]
then
    # Scary install script goes brrr
    curl -s "https://get.sdkman.io" | bash
fi
