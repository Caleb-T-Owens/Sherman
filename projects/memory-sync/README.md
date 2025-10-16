# memory-sync

Bidirectional git sync for Sherman's memory files across multiple machines.

## Setup

```bash
cargo build --release
./target/release/memory-sync init
```

First run creates config at `~/sherman_memories/sync-config.json`.

## Usage

```bash
memory-sync           # Full bidirectional sync
memory-sync push      # Push local → remote
memory-sync pull      # Pull remote → local
memory-sync status    # Check workspace status
```

## How it works

Maintains a git workspace at `~/.memory-sync-workspace/` that syncs:
- `~/sherman_memories/` → `workspace/main/`
- `~/Sherman/projects/*/.agents/memories/` → `workspace/projects/<name>/`

Sync process (fetch-first):
1. Pull remote changes (fetch + merge)
2. Copy remote changes to local if any
3. Collect local files into workspace
4. Commit local changes
5. Push (guaranteed success since we pulled first)

## Conflicts

If merge conflicts occur:
1. Tool writes conflict markers to workspace files
2. Lists conflicting files
3. Manual resolution:
   ```bash
   cd ~/.memory-sync-workspace
   # Edit files, remove markers
   git add <files>
   git commit
   memory-sync sync
   ```

No data is lost - both sides preserved with conflict markers.

## Notes

- Uses SSH agent for git auth
- Auto-detects `main` vs `master` branch
- Projects not present locally are kept in repo but not synced down
- Config file excluded from sync
