# Cap Deployset

Cap is a self-hosted Loom alternative. This deployset runs:

- Cap Web
- Cap media server
- MySQL
- MinIO

It assumes host-level `cloudflared` or another HTTP proxy in front of the app. There is no nginx here.

## Hostnames

Cap needs two public URLs if you use the bundled MinIO:

- App: `https://cap.cto.je`
- Object storage: `https://files-cap.cto.je`

If you only want one public hostname, you will need to swap the bundled MinIO setup for external S3/R2 or add a custom storage proxy layer.

## Ports

- `127.0.0.1:3015` -> Cap Web
- `127.0.0.1:9015` -> MinIO API
- `127.0.0.1:9016` -> MinIO console

Everything is bound to localhost so it can sit behind Cloudflare cleanly.

## 1. Create persistent directories

```bash
mkdir -p "$HOME/volumes/cap/mysql" "$HOME/volumes/cap/minio"
```

## 2. Set environment variables

Create a `.env` file in this folder or export these before deploy:

```bash
CAP_URL=https://cap.cto.je
S3_PUBLIC_URL=https://files-cap.cto.je
S3_BUCKET=cap
MYSQL_PASSWORD=<strong-mysql-password>
MYSQL_ROOT_PASSWORD=<strong-mysql-root-password>
MINIO_ROOT_USER=cap
MINIO_ROOT_PASSWORD=<strong-minio-password>
NEXTAUTH_SECRET=<64-hex-char-secret>
DATABASE_ENCRYPTION_KEY=<64-hex-char-secret>
MEDIA_SERVER_WEBHOOK_SECRET=<64-hex-char-secret>
```

Generate the three 64-hex secrets with:

```bash
openssl rand -hex 32
```

Optional:

```bash
RESEND_API_KEY=<resend-api-key>
RESEND_FROM_DOMAIN=cto.je
GOOGLE_CLIENT_ID=<google-client-id>
GOOGLE_CLIENT_SECRET=<google-client-secret>
DEEPGRAM_API_KEY=<deepgram-api-key>
GROQ_API_KEY=<groq-api-key>
OPENAI_API_KEY=<openai-api-key>
```

## 3. Start services

```bash
docker compose up -d
```

## 4. Cloudflare setup

This deployset is designed for a host-managed Cloudflare Tunnel if you do not want nginx/caddy on the host.

Suggested tunnel ingress:

- `cap.cto.je` -> `http://localhost:3015`
- `files-cap.cto.je` -> `http://localhost:9015`

Keep the MinIO console private and use the local port `9016` when you need it.

If you are only using orange-cloud DNS proxying and not Tunnel, Cloudflare still needs an origin listening on a supported public port. In that case you would need an origin proxy on `80/443`, which this deployset intentionally does not add.

## 5. First login

If email is not configured, login links are printed in the Cap logs:

```bash
docker compose logs cap-web
```

Then point Cap Desktop at:

```bash
https://cap.cto.je
```

## Data

- MySQL: `$HOME/volumes/cap/mysql`
- MinIO: `$HOME/volumes/cap/minio`

Back up both.
