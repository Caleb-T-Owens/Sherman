# Configure

A CLI tool to replace the Makefile-based configuration system in Sherman. It manages configset installations with automatic dependency resolution.

## Installation

Build from source (requires Rust 1.70+):

```bash
cd configure
cargo build --release
# Binary is at ./target/release/configure
```

Or install to PATH:

```bash
cargo install --path .
```

## Usage

### Run a configuration file directly

```bash
configure ./configsets/shared/git/configurable.yaml
# or just point to the directory
configure ./configsets/shared/git
```

### Run a task by name

```bash
# Run with dependencies
configure -t neovim

# Run without dependencies  
configure -t neovim --no-deps
```

### List available tasks

```bash
configure -l
# or
configure --list
```

### Other options

```bash
# Dry run - see what would be executed
configure -t neovim -n

# Specify configsets directory
configure --configsets-dir /path/to/configsets -t git
```

## configurable.yaml Format

Each configset should have a `configurable.yaml` file:

```yaml
name: git
script: ./install.sh
description: Configure git with appropriate gitconfig
dependencies:
  - shared/brew    # Paths relative to configsets root
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Identifier for the configurable |
| `script` | Yes | Path to installation script (relative to yaml location) |
| `description` | No | Human-readable description |
| `dependencies` | No | List of paths to dependent configurables |

## How It Works

Configure tracks completed tasks **in-memory during a single execution**. This means:

- Each task runs exactly once per invocation (handles diamond dependencies)
- No persistent state between runs — every `configure` invocation starts fresh
- No lock files to manage or clean up

This design fits the typical use case: run all your configs in one go when setting up a machine.

## Migration from Makefiles

1. Create a `configurable.yaml` in each configset directory
2. Specify dependencies explicitly (instead of relying on Makefile.work ordering)
3. Run `configure -l` to verify discovery
4. Run `configure -t <task>` instead of `make -C configsets/<task>`

## Example

```bash
# Old way
cd configsets && make -f Makefile.work

# New way
configure -t neovim  # Runs git dependency first, then neovim
```
