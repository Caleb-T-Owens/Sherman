pushd $SHERMAN_DIR/projects/project-cloner

if type -a bun >&2;
then
    echo "Bun installed"
else
    curl -fsSL https://bun.sh/install | bash

    source /home/electron/.bashrc
fi

bun install

popd
