# configure

A minimal configset runner for Sherman, written in C.

## Building

```bash
make
```

Requires only a C compiler (`cc` or `gcc`) - no external dependencies.

## Usage

```bash
# List available tasks
configure -l
configure --list

# Run a task (with dependencies)
configure -t shared/git

# Run without dependencies
configure -t shared/git --no-deps

# Run a profile (work, home, charm, anti)
configure -p work
configure --profile charm

# List available profiles
configure --profiles

# Run a specific config file
configure ./configsets/shared/git/configurable.conf

# Show help
configure -h
```

## How it works

1. Discovers all `configurable.conf` files in `configsets/`
2. Parses task definitions (name, script, dependencies)
3. Uses topological sort for dependency resolution
4. Executes scripts in order, tracking completed tasks in-memory

## configurable.conf format

Each configset needs a `configurable.conf` (simple line-based, easy to parse):

```
name: shared/git
script: ./install.sh
deps: macos/brew shared/rustup
```

- `name`: Task identifier (typically `category/name`)
- `script`: Path to install script (relative to configurable.conf)
- `deps`: Space-separated list of dependencies (optional)

## Profiles

Profiles are lists of tasks to run for a specific environment. They live in `configsets/profiles/`:

```
# profiles/work.conf
macos/brew
shared/git
shared/neovim
# Actions
shared/action-clone-projects
```

Available profiles:
- `work` - macOS work machine
- `home` - macOS home machine  
- `charm` - Charm deployment
- `anti` - Debian (anti) setup

## Environment

- Looks for `./configsets/` first (run from repo root)
- Falls back to `$SHERMAN_DIR/configsets/`
- Then `$HOME/Sherman/configsets/`

## Example

```bash
$ ./configure -l
Available tasks (34):

  shared/neovim                 -> shared/ripgrep
  shared/ripgrep                -> shared/rustup, shared/action-sync-buildables
  shared/rustup
  macos/zsh
  ...

$ ./configure -t shared/neovim
=== Running: shared/rustup ===
...
=== Running: shared/ripgrep ===
...
=== Running: shared/neovim ===
...
```
