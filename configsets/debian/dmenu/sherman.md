# dmenu

Built from the cloned buildables repo. (The old install.sh depended on
itself — a cycle the make-lock files papered over; dropped here.)

```deps
debian/action-aptfile-sync
shared/action-sync-buildables
```

```always
```

```install
cd $SHERMAN_DIR/buildables/dmenu/repo
sudo make install
```
