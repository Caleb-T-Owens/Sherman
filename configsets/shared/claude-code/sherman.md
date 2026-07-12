# Claude Code global config

Runs every apply: the ~/.claude guard depends on machine state outside the
input hash, so a recorded "success" while it was missing must not stick.

```always
```

```in
CLAUDE.md
```

```out
$HOME/.claude/CLAUDE.md
```

```install
if [ ! -d "$HOME/.claude" ]; then
    echo "~/.claude does not exist; skipping"
    exit 0
fi
cp CLAUDE.md $HOME/.claude/CLAUDE.md
```
