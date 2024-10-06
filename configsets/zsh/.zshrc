eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PROMPT='%(?.%F{green}√.%F{red}X)%f %1~ > '

eval "$(rbenv init - zsh)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# no it doesn't...
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

alias code="codium"

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
