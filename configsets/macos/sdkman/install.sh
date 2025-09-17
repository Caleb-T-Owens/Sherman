#!/bin/bash

if [ -e /opt/homebrew/opt/sdkman-cli/libexec ]
then
    export SDKMAN_DIR="/opt/homebrew/opt/sdkman-cli/libexec"
    [[ -s "/opt/homebrew/opt/sdkman-cli/libexec/bin/sdkman-init.sh" ]] && source "/opt/homebrew/opt/sdkman-cli/libexec/bin/sdkman-init.sh"
    sdk selfupdate
else
    # Scary install script goes brrr
    curl -s "https://get.sdkman.io" | bash
fi
