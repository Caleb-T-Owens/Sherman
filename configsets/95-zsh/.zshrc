if [ -e /opt/homebrew/bin/brew ]
then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -e $HOME/.nvm ]
then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion
fi

export PROMPT='%(?.%F{green}√.%F{red}X)%f %1~ > '

if type -a rbenv >&2;
then
    eval "$(rbenv init - zsh)"
fi

if [ -e $HOME/.sdkman ]
then
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

if type -a codium >&2;
then
    alias code="codium"
fi

if type -a ng >&2;
then
    source <(ng completion script)
fi

function pp {
    if [ -e "pnpm-lock.yaml" ]
    then
        pnpm $*
    elif [ -e "yarn.lock" ]
    then
        yarn $*
    elif [ -e "bun.lockb" ]
    then
        bun $*
    elif [ -e "package-lock.json" ]
    then
        npm $*
    fi
}

function sherman_reload {
    if [ -e $HOME/sherman/bin/run ]
    then
        source "$HOME/sherman/bin/run"
    fi
}

function sherman_electron_deploy {
    if [ -e $HOME/sherman/bin/electron_deploy ]
    then
        source "$HOME/sherman/bin/electron_deploy"
    fi
}
