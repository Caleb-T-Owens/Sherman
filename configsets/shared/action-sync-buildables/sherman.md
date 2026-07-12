# action: sync buildables

Clones/updates the buildables and re-applies any patc patch sets.

```deps
shared/project-cloner2
shared/patc
```

```always
```

```install
cd $SHERMAN_DIR/buildables
CLONER_PROFILE=$SHERMAN_ENV project-cloner2

for folder in */; do
    cd $SHERMAN_DIR/buildables/$folder
    if [ -e patc.json ]; then
        patc reapply
    fi
done
```
