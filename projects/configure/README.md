# configure

A minimal configset runner for Sherman, written in C.

## Building

```bash
make
make install  # installs to $HOME/Sherman/bin/
```

Requires only a C compiler (`cc` or `gcc`) - no external dependencies.

## Usage

```bash
# List available tasks
configure -l
configure --list

# Run a task (with dependencies)
configure -t git

# Run without dependencies
configure -t git --no-deps

# Run a specific config file
configure ./path/to/configurable.yaml

# Show help
configure -h
```

## How it works

1. Discovers all `configurable.yaml` files in `$SHERMAN_DIR/configsets/`
2. Parses task definitions (name, script, dependencies)
3. Uses topological sort for dependency resolution
4. Executes scripts in order, tracking completed tasks in-memory

## configurable.yaml format

Each configset needs a `configurable.yaml`:

```yaml
name: git
script: ./install.sh
dependencies:
  - shared/brew
  - shared/rustup
```

- `name`: Unique task identifier (typically `category/name` like `shared/git`)
- `script`: Path to install script, relative to the configurable.yaml location
- `dependencies`: List of task names that must run first (optional)

## Environment

- `SHERMAN_DIR`: Base directory (defaults to `$HOME/Sherman`)
- Uses `bash -e` to execute scripts (stops on first error)
