# action: clone projects

Syncs the repos listed in projects/cloned.json for this env's profile.

```deps
shared/project-cloner2
```

```always
```

```install
cd $SHERMAN_DIR/projects
CLONER_PROFILE=$SHERMAN_ENV project-cloner2
```
