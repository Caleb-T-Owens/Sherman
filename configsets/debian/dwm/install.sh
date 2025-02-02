#!/bin/bash

# Depends on action-aptfile-sync
(cd $SHERMAN_DIR/configsets/debian/action-aptfile-sync && make)
# Depends on xorg
(cd $SHERMAN_DIR/configsets/debian/xorg && make)
# Depends on action-sync-buildables for dwm clone
(cd $SHERMAN_DIR/configsets/shared/action-sync-buildables && make)

# Install dwm
pushd $SHERMAN_DIR/buildables/dwm/repo

sudo make install

popd
