if type -a bun >&2;
then
    echo "Bun installed"
else
    curl -fsSL https://bun.sh/install | bash

    source /home/electron/.bashrc
fi
