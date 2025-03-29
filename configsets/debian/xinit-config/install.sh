#!/bin/bash

# Depends on 
(cd $SHERMAN_DIR/configsets/debian/action-aptfile-sync && make)
# Depends on xorg
(cd $SHERMAN_DIR/configsets/debian/xorg && make)
# Depends on dwm
(cd $SHERMAN_DIR/configsets/debian/dwm && make)

# Copy .xinitrc
cp .xinitrc $HOME/.xinitrc
