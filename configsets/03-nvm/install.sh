# nvm should have been installed by brew

# nvm post install
if [ ! -e $HOME/.nvm ]
then
    mkdir $HOME/.nvm
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

nvm install --lts=iron
nvm alias default lts/iron

# Would be good to have a neater way of managing global packages
npm install -g @angular/cli
