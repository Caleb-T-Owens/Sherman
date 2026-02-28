# tabs

Minimal Rust + Axum server-rendered auth starter app using MiniJinja templates and SQLite via sqlx.

## Stack

- axum + tokio backend
- minijinja templates (plain HTML forms, no frontend framework)
- static CSS from `/static`
- sqlite with sqlx runtime queries (`query` + `bind` + `Row::get`)
- argon2id password hashing with server-side sqlite sessions
- CSRF protection for all POST forms via synchronizer token

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

By default, server starts at `http://127.0.0.1:3000`.

To make it reachable from other devices on your network, bind to all interfaces:

```bash
HOST=0.0.0.0 PORT=3000 cargo run
```

You can also set `BIND_ADDR` directly (takes priority over `HOST` + `PORT`).

## Auth and sessions

- `GET /register`, `POST /register`, `GET /login`, `POST /login`, and `POST /logout` are server-rendered form flows.
- `GET /` is an authenticated account home page; unauthenticated requests redirect to `/login`.
- Session cookie is `HttpOnly`, `SameSite=Lax`, `Path=/`, and has max age set server-side.
- Use `COOKIE_SECURE=true` in production HTTPS deployments to set the `Secure` cookie flag.
