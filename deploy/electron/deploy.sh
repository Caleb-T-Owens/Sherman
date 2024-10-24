#!/bin/bash

set -eu -o pipefail

echo "Updating nginx config"

sudo find /etc/nginx/sites-enabled -maxdepth 1 -type f -name '*' -delete

sudo cp $SHERMAN_DIR/deploy/electron/domains/* /etc/nginx/sites-enabled

echo "Restarting nginx..."

sudo systemctl restart nginx

echo "Restared nginx"

echo "Deploying services"

for service in $SHERMAN_DIR/deploy/electron/services/*
do
    if [ -e $service/deploy.sh ]
    then
        echo "Deploying $service"
        source $service/deploy.sh
    fi
done

echo "Finished deploying"
