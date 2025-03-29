export SHERMAN_DIR=$HOME/Sherman
export SHERMAN_ENV="$(cat $HOME/Sherman/CURRENT_ENV)"
export SHERMAN_THEME="$(cat $HOME/Sherman/THEME)"

if [[ $SHERMAN_ENV == home || $SHERMAN_ENV == work ]]
then
    export SHERMAN_PLATFORM=macos
fi
if [[ $SHERMAN_ENV == anti ]]
then
    export SHERMAN_PLATFORM=debian
fi

export PATH="$SHERMAN_DIR/bin:$PATH"
