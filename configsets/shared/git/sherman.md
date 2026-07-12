# git

Picks the gitconfig for the current env, so this stays a script; declaring
the output still gives us undo for free.

```in
.gitconfig.work
.gitconfig.anti
.gitconfig.home
```

```out
$HOME/.gitconfig
```

```install
if [ $SHERMAN_ENV = work ]; then
    cp .gitconfig.work $HOME/.gitconfig
elif [ $SHERMAN_ENV = anti ]; then
    cp .gitconfig.anti $HOME/.gitconfig
else
    cp .gitconfig.home $HOME/.gitconfig
fi
```
