#!/bin/bash

# We could totally be more efficient and check if there was a new version, but I'm being *pragmatic*
rm $SHERMAN_DIR/bin/bun

if [ $SHERMAN_PLATFORM = macos ]
then
    wget https://github.com/oven-sh/bun/releases/latest/download/bun-darwin-aarch64.zip -O bun.zip
    tar -xvf bun.zip
    cp bun-darwin-aarch64/bun $SHERMAN_DIR/bin/bun
    rm bun.zip
    rm -r bun-darwin-aarch64
fi

if [ $SHERMAN_PLATFORM = debian ]
then
    wget https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip -O bun.zip
    tar -xvf bun.zip
    cp bun-linux-x64/bun $SHERMAN_DIR/bin/bun
    rm bun.zip
    rm -r bun-linux-x64
fi