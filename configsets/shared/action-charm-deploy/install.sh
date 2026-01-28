#!/bin/bash

if [ $SHERMAN_ENV = charm ]
then
    echo "Running deploydeploy for charm services..."
    pushd $SHERMAN_DIR/deploy
    $SHERMAN_DIR/bin/deploydeploy deploy -s charm
    popd
fi
