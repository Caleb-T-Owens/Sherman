# tabs

Minimal Rust + Axum server-rendered notes app using MiniJinja templates and SQLite via sqlx.

## Stack

- axum + tokio backend
- minijinja templates (plain HTML forms, no frontend framework)
- static CSS from `/static`
- sqlite with sqlx runtime queries (`query` + `bind` + `Row::get`)

## Prerequisites

- Rust toolchain
- `sqlx-cli` installed:

```bash
cargo install sqlx-cli --no-default-features --features sqlite
```

## Setup

```bash
cp .env.example .env
mkdir -p data
```

## Run migrations with sqlx-cli

```bash
source .env
sqlx migrate run
```

## Run app

```bash
cargo run
```

Server starts at `http://127.0.0.1:3000`.
