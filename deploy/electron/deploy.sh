#!/bin/bash



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
