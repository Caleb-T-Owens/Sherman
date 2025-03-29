#!/bin/bash

# Depends on action-aptfile-sync
(cd $SHERMAN_DIR/configsets/debian/action-aptfile-sync && make)
# Depends on action-sync-buildables for dwm clone
(cd $SHERMAN_DIR/configsets/shared/action-sync-buildables && make)
# Depends on dmenu (not for building, but for my setup)
(cd $SHERMAN_DIR/configsets/debian/dmenu && make)

# Install dmenu
pushd $SHERMAN_DIR/buildables/dmenu/repo

sudo make install

popd
