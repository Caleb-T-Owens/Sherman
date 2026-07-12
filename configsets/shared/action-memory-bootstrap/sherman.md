# action: memory bootstrap

Installs the sync config and pulls remote memories on every apply.

```deps
shared/memory-sync
```

```always
```

```install
mkdir -p $HOME/sherman_memories

echo "Installing memory sync configuration"
cp sync-config.json.template $HOME/sherman_memories/sync-config.json

echo "Syncing memories from remote repository..."
memory-sync sync

echo "Memory bootstrap complete"
```
