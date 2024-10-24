#!/bin/bash

set -eu -o pipefail

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

echo "Updating nginx config"

rm /etc/nginx/sites-enabled/*

cp $HOME/sherman/deploy/electron/domains/* /etc/nginx/sites-enabled
