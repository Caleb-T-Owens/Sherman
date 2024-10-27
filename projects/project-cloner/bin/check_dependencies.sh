pushd $SHERMAN_DIR/proejcts/project-cloner

if type -a bun >&2;
then
    echo "Bun installed"
else
    echo "Bun required to run project cloner"
    exit 1
fi

bun install

popd
