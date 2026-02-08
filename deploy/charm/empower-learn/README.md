# Empower Learn Deployset

A learning platform with React frontend and Rails API backend.

## Stack

- **Frontend**: React 19 + Vite + MUI + Redux (served by nginx)
- **Backend**: Rails 8 + SQLite + Thruster

## Port

- **3014**: Frontend (nginx with SPA + API proxy)

## Setup

### 0. Repository sync hook

Before each deploy, `install.sh` runs automatically from this folder. It ensures
`./repo` exists in this deploy set, fetches from `origin`, and hard
resets the checkout to `origin/main`.
This deploy set no longer uses artifact symlinks.

### 1. Create volume directory

```bash
mkdir -p $HOME/volumes/empower-learn/storage
```

### 2. Set environment variables

Create a `.env` file or export:

```bash
export RAILS_MASTER_KEY=<your-master-key>
```

### 3. Build and run

```bash
docker compose up -d --build
```

### 4. Check logs

```bash
docker compose logs -f
```

## Access

- Frontend: http://localhost:3014
- API: http://localhost:3014/api

## Architecture

```
                    ┌─────────────────┐
    :3014 ────────> │    frontend     │
                    │    (nginx)      │
                    └────────┬────────┘
                             │
            /api/*           │  static files
                             │
                    ┌────────v────────┐
                    │    backend      │
                    │    (rails)      │
                    └─────────────────┘
```

## Data Persistence

SQLite databases stored at `$HOME/volumes/empower-learn/storage/`
