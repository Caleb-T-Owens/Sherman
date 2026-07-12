# sherman

The tool that applies [configsets](../../configsets). ~1000 lines of C11,
no dependencies beyond a C compiler (Xcode CLT / build-essential).
`bin/sherman` compiles it on every use.

```
bin/sherman              # apply the env in CURRENT_ENV
bin/sherman status       # what would run / is up to date / would be undone
bin/sherman apply home   # apply a specific env
bin/sherman -j 1 apply   # serial (default: 16 jobs)
```

## The format

Each configset is a directory under `configsets/` with a `sherman.md`.
The file is prose; the only rule is that a line starting with ``` opens a
fenced block and the tag decides what it is. Unrecognised tags (```sh etc.)
and everything outside blocks are documentation. Repeated blocks concatenate.

| tag | meaning |
|---|---|
| `deps` | configsets that must finish first. `macos:` / `debian:` prefix scopes a dep to one platform. |
| `change` | declarative, invertible steps. v1: `copy SRC DST` (file or dir; dir replaces DST wholesale). SRC is repo-relative, no spaces; DST is absolute, spaces fine. |
| `in` | extra hashed inputs (files or dirs) for scripts — e.g. a Brewfile. Missing input = loud failure. |
| `out` | files a script produces; recorded so removal can undo them. |
| `install` | bash, run with `-e`, cwd = configset dir, when the node is new or its hash changed. Runs after `change`. |
| `uninstall` | bash, run when the configset is dropped from the env. |
| `always` | run on every apply (updaters, sync actions). |

`$VAR`/`${VAR}` are expanded in `change`/`in`/`out` lines; undefined vars are
fatal. Scripts get normal shell expansion at runtime instead, plus
`SHERMAN_DIR`, `SHERMAN_ENV`, `SHERMAN_PLATFORM`, `SHERMAN_THEME`, and
`SHERMAN_DIR/bin` + `~/.cargo/bin` on PATH.

An **env** is just a configset with only deps: `configsets/envs/work.md`.

## Semantics

- A node re-runs when its **input hash** changes: the sherman.md text, the
  env name, every `change` SRC, every `in` path (content and permission
  bits; symlinks hash their target), or when a recorded output is missing
  or its content/mode drifts. Deps re-running does *not* re-run dependents.
  An unreadable or missing input fails that node only.
- State lives in `~/.local/state/sherman/<name>/` (`hash`, `outs` manifest
  with per-file sha256 and mode, `undo` snapshot, last `log`). The undo snapshot means
  a configset can be un-applied even after its directory is deleted.
- **Removal**: after each apply, any state entry no longer in the env's graph
  is undone — its `uninstall` snapshot runs (cwd = state dir), then each
  recorded out is deleted *only if its content still matches the recorded
  hash* (hand-edited files are left with a warning) *and no current node
  claims the path* (so renaming a configset never deletes what the new name
  just applied). GC only runs when the applied env matches `CURRENT_ENV` —
  a typo'd `sherman apply <env>` cannot mass-undo the machine's real env.
- Failures poison their dependents (skipped) but the rest of the graph
  continues. Job output streams live as `<node> | <line>` (colored per node
  on a tty), is teed into the state log, and is recapped on failure.

## Ceilings (deliberate, upgrade when they bite)

- `copy` is the only verb; a `link` verb would make repo edits live.
- Undo of removed configsets runs in arbitrary order.
- Dir-copy undo removes files but leaves empty directories behind.
- Force a re-run by deleting the state dir: `rm -r ~/.local/state/sherman/<name>`.
- Live blocks: never tag an illustrative fenced block with a real tag name;
  use ```sh fences in prose. A script that must *contain* a bare ``` line
  gets a longer opening fence (````), CommonMark-style.

## Reading the code

Start with the big comment at the top of [sherman.h](sherman.h) — it has the
file-by-file reading order, the data-flow diagram for an apply, and the
memory model (one arena, nothing freed, no ownership to track). Each .c
file then opens with a paragraph saying what it owns.

`./test.sh` is the end-to-end check.
