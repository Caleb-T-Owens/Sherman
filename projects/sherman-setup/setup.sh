pushd $HOME/Sherman

if [ ! -e bin/bun ]
then
    if [ -e bin/buntmp ]
        rm -r bin/buntmp
    fi

    pushd bin/buntmp

    if [[ $OSTYPE == "darwin"* ]]
    then
        curl -O -L https://github.com/oven-sh/bun/releases/latest/download/bun-darwin-aarch64.zip
    else
    fi

    popd
fi

popd