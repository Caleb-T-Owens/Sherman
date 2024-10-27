#!/bin/bash

source /home/electron/.bashrc

echo "Preparing project cloner"

source "$SHERMAN_DIR/projects/project-cloner/bin/electron_prepare.sh"

echo "Running project cloner"

source "$SHERMAN_DIR/bin/clone"

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
