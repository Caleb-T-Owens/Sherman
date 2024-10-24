#!/bin/bash

set -eu -o pipefail

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

echo "Updating nginx config"

find /etc/nginx/sites-enabled -maxdepth 1 -type f -name '*' -delete

cp /home/electron/sherman/deploy/electron/domains/* /etc/nginx/sites-enabled

echo "Restarting nginx..."

systemctl restart nginx

echo "Restared nginx"

echo "Deploying services"

for service in $HOME/sherman/deploy/electron/services/*
do
    if [ -e $service/deploy.sh ]
    then
        echo "Deploying $service"
        source $service/deploy.sh
    fi
done

echo "Finished deploying"
