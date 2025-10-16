# Agent Tools

A modular CLI toolkit designed to give AI agents powerful capabilities for web browsing, system interaction, and more.

## Design Philosophy

**Extensibility First**: Built as a plugin-style architecture where new tools can be easily added as subcommands. Each tool is self-contained and focused on a specific capability.

**Agent-Friendly**: Commands are designed to be easily parsable and scriptable by AI agents, with structured output (JSON where appropriate) and clear, predictable interfaces.

**Daemon Architecture**: Long-running operations (like browser sessions) run as background daemons with CLI commands for interaction, avoiding startup overhead and maintaining state.

## Architecture

```
agent-tools
├── src/
│   ├── main.rs          # CLI entry point and subcommand routing
│   ├── commands/        # Individual tool implementations
│   │   ├── mod.rs
│   │   └── browse/      # Browser automation tool
│   │       ├── mod.rs
│   │       ├── daemon.rs    # Headless Chromium daemon
│   │       └── commands.rs  # CLI command handlers
│   └── common/          # Shared utilities
│       ├── mod.rs
│       └── daemon.rs    # Daemon lifecycle utilities
└── Cargo.toml
```

## Current Tools

### Browse - Web Browser Automation

Headless Chromium browser controlled via CLI for web navigation, scraping, and interaction.

**Daemon**: `agent-tools browse daemon start`
**Commands**:
- `navigate <url>` - Navigate to URL
- `screenshot [selector]` - Capture screenshot
- `click <selector>` - Click element
- `type <selector> <text>` - Type into input
- `extract <selector>` - Extract element text/HTML
- `eval <js>` - Execute JavaScript
- `wait <selector>` - Wait for element
- `tabs list|new|switch <id>` - Manage tabs

## Adding New Tools

1. Create a new module in `src/commands/`
2. Implement the subcommand using `clap`
3. Add to the main command enum in `src/main.rs`
4. Document in this README

Tools should be:
- **Self-contained**: Minimal dependencies on other tools
- **Focused**: Do one thing well
- **Scriptable**: Predictable output formats
- **Documented**: Clear help text and examples

## Development

```bash
# Build
cargo build --release

# Run
cargo run -- browse navigate https://example.com

# Install locally
cargo install --path .
```

## Future Tool Ideas

- **fetch** - Advanced HTTP client with session management
- **parse** - HTML/XML/JSON parsing and extraction
- **db** - SQLite database querying
- **file** - Advanced file operations
- **git** - Git repository interaction
- **llm** - LLM API wrappers for self-reflection/delegation
