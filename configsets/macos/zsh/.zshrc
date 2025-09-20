source $HOME/Sherman/bin/utils/base.sh

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

# if type -a codium >&2;
# then
#     alias code="codium"
# fi

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

# Disable some of the worst TUI bullshit I've ever seen
export COMPOSE_MENU=0


if [ -e /opt/homebrew/opt/sdkman-cli/libexec ]
then
    export SDKMAN_DIR="/opt/homebrew/opt/sdkman-cli/libexec"
    [[ -s "/opt/homebrew/opt/sdkman-cli/libexec/bin/sdkman-init.sh" ]] && source "/opt/homebrew/opt/sdkman-cli/libexec/bin/sdkman-init.sh"
fi

# Local bin seems like a good idea.
export PATH="$HOME/.local/bin:$PATH"