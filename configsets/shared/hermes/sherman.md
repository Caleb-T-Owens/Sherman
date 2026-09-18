# Hermes Agent

Nous Research's agent, pointed at Codex/`gpt-5.6-sol` — the same subscription
`bin/sol` proxies for Claude Code, but native rather than through cliproxyapi,
so there's no local endpoint to keep alive. No secret in here: Hermes imports
the ChatGPT OAuth from `~/.codex/auth.json` on first run and keeps its own copy
in `~/.hermes/auth.json`.

The whole file is copied, so anything Hermes persists into `config.yaml` itself
(`/codex-runtime`, `hermes model`) is lost on the next apply — edit
`config.yaml` here instead.

```deps
macos/brew
```

```change
copy config.yaml $HOME/.hermes/config.yaml
```
