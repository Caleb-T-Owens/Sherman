# Matrix (Synapse) Deployset (Cloudflare Tunnel, Version-Controlled Config)

This deployset keeps Synapse configuration in git and renders `/data/homeserver.yaml` from environment variables at container startup.

## Files in git

-   `compose.yaml`
-   `synapse/start.sh`
-   `synapse/render_homeserver.py`

No on-server config generation/editing is required.

This will conflict

## What this setup does

oasdfsadf

-   Synapse + Postgres via Docker Compose.
-   Registration enabled by default.
-   Public HTTPS expected through Cloudflare Tunnel.
-   Internal origin stays HTTP (`cloudflared -> synapse:8008`).

## Capability breakdown

`Synapse` (this deployset) provides:

-   Account registration and password login.
-   User/device sessions and access tokens.
-   Room and Space state/storage.
-   Federation with other Matrix homeservers.
-   Admin APIs and admin user privileges.

`Cinny` (or Element/other clients) provides:

-   User interface for sign-up/login.
-   UI for chats, Spaces, room settings, invites, and profile actions.
-   A way to talk to your homeserver over the Matrix client APIs.

Cinny is optional. Any standards-compatible Matrix client can connect to this server.

## Registration and login behavior in this setup

Current defaults from `compose.yaml`:

-   `SYNAPSE_ENABLE_REGISTRATION=true`
-   `SYNAPSE_ENABLE_REGISTRATION_WITHOUT_VERIFICATION=true`
-   `SYNAPSE_REGISTRATION_REQUIRES_TOKEN=false`

What that means:

-   Anyone who can reach your homeserver can self-register a local account.
-   No email/captcha/token is required for registration.
-   Login is username/password through Matrix client APIs.
-   You can still create an admin account directly with `register_new_matrix_user -a`.

If you want open registration later with less abuse risk, set:

-   `SYNAPSE_REGISTRATION_REQUIRES_TOKEN=true`

and issue tokens instead of fully open signup.

## "Creating a server" in Matrix terms

Matrix has different layers than Discord:

-   Homeserver: your Synapse instance (infrastructure + account authority).
-   Space: closest concept to a Discord server.
-   Room: closest concept to a Discord text/voice channel.

In practice with this deploy:

-   You run exactly one homeserver instance.
-   Users do not create new homeservers on your host.
-   Registered users can create Spaces/rooms (subject to room power levels and moderation controls).
-   Federated users from other homeservers can participate in federated rooms/spaces.

## 1. Set required environment variables

```bash
export MATRIX_SERVER_NAME=example.com
export SYNAPSE_PUBLIC_BASEURL=https://matrix.example.com/
export POSTGRES_PASSWORD='<strong-db-password>'
export SYNAPSE_FORM_SECRET="$(openssl rand -hex 32)"
export SYNAPSE_MACAROON_SECRET_KEY="$(openssl rand -hex 32)"
export CLOUDFLARE_TUNNEL_TOKEN='<your-tunnel-token>'
```

Notes:

-   `MATRIX_SERVER_NAME` is your Matrix server name (appears in MXIDs like `@user:example.com`).
-   `SYNAPSE_PUBLIC_BASEURL` is where clients connect.
-   Keep `SYNAPSE_FORM_SECRET` and `SYNAPSE_MACAROON_SECRET_KEY` stable after first deploy.

## 2. Create persistent directories

```bash
mkdir -p "$HOME/volumes/matrix/synapse" "$HOME/volumes/matrix/postgres"
```

## 3. Start services

With bundled tunnel container:

```bash
docker compose --profile tunnel up -d
```

Without bundled tunnel container:

```bash
docker compose up -d synapse db
```

## 4. Cloudflare Tunnel ingress

Set tunnel ingress hostname/service:

-   Hostname: `matrix.example.com`
-   Service: `http://synapse:8008`

Do not place Cloudflare Access auth in front of `/_matrix/*`.

## 5. Create admin account

```bash
docker compose exec synapse register_new_matrix_user \
  -c /data/homeserver.yaml \
  -u <admin-username> \
  -p '<strong-password>' \
  -a \
  http://localhost:8008
```

## Config knobs (env vars)

-   `SYNAPSE_ENABLE_REGISTRATION` default `true`
-   `SYNAPSE_ENABLE_REGISTRATION_WITHOUT_VERIFICATION` default `true`
-   `SYNAPSE_REGISTRATION_REQUIRES_TOKEN` default `false`
-   `SYNAPSE_REPORT_STATS` default `no`

## Federation on 443

If `MATRIX_SERVER_NAME` and `SYNAPSE_PUBLIC_BASEURL` host differ, publish:

-   `https://<MATRIX_SERVER_NAME>/.well-known/matrix/server` with `{"m.server":"matrix.example.com:443"}`
-   `https://<MATRIX_SERVER_NAME>/.well-known/matrix/client` with `{"m.homeserver":{"base_url":"https://matrix.example.com"}}`
