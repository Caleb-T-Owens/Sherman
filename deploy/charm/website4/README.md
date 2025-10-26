# Website4 Deployment

Deployment configuration for website4 using Docker Compose and nginx.

## Overview

Website4 is a static Astro site that builds to pure HTML/CSS/JS files. This deployment uses a multi-stage Docker build:

1. **Build stage**: Uses Node.js to build the Astro site with pnpm
2. **Production stage**: Uses nginx Alpine to serve the static files

## Architecture

- **Web Server**: nginx (Alpine Linux)
- **Port**: 3011 (maps to container port 80)
- **Build Tool**: pnpm
- **Framework**: Astro v5.15.1

## Files

- **Dockerfile**: Multi-stage build (Node.js build → nginx serve)
- **nginx.conf**: nginx configuration with gzip compression and security headers
- **compose.yaml**: Docker Compose service definition
- **config.json**: Artifact path configuration

## Performance Features

The nginx configuration includes:

- **Gzip compression** for text assets (HTML, CSS, JS, JSON)
- **Cache headers** for static assets (1 year expiry for images, fonts, etc.)
- **Security headers** (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- **Try-files fallback** for clean URLs

## Deployment

```bash
# Build the Docker image
docker compose build

# Start the service
docker compose up -d

# View logs
docker compose logs -f

# Stop the service
docker compose down
```

## Access

Once running, the website is available at:
- http://localhost:3011

## Build Process

The Dockerfile performs these steps:

1. Copy source code to build container
2. Install pnpm globally
3. Install dependencies with `pnpm install --frozen-lockfile`
4. Build the site with `pnpm build` (outputs to `/app/dist`)
5. Copy built files to nginx container
6. Configure nginx with custom config
7. Expose port 80

## Differences from Website3

Website3 uses Node.js SSR, while website4 uses static generation:

- **Website3**: Node.js runtime required, port 3010
- **Website4**: nginx static file server, port 3011

Website4 is more performant and has a smaller Docker image size since it only needs nginx, not the full Node.js runtime.

## Troubleshooting

If the build fails:

1. Check that `$HOME/Sherman/projects/website4` exists
2. Verify the nginx.conf is in the project directory
3. Ensure Docker has enough resources for the build

If the container starts but shows errors:

1. Check nginx logs: `docker compose logs web`
2. Verify the dist folder was created during build
3. Test nginx config: `docker compose exec web nginx -t`
