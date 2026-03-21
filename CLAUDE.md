# NeXroll — Preroll Manager (Fork)

Forked preroll management system for Plex and Jellyfin. FastAPI backend + prebuilt React frontend, runs as a Docker container on Unraid.

## Stack

- **Backend:** FastAPI (Uvicorn), Python 3.12 — `NeXroll/backend/main.py`
- **Frontend:** Prebuilt React SPA — `NeXroll/frontend/build/`
- **Storage:** SQLite at `/data/nexroll.db`, prerolls at `/data/prerolls`
- **Image:** `ghcr.io/artic5693/nexroll:latest` (fork), `jbrns/nexroll:latest` (upstream)
- **Port:** 9393

## URLs

- Web UI: `http://192.168.1.219:9393`
- API docs: `http://192.168.1.219:9393/docs`
- Health: `http://192.168.1.219:9393/health`

## Deploy

```bash
# Build and push image (CI handles this via .github/workflows/)
docker build -t ghcr.io/artic5693/nexroll:latest .
docker push ghcr.io/artic5693/nexroll:latest

# On Unraid — pull and restart
ssh -i ~/.ssh/unraid root@192.168.1.219 "docker pull ghcr.io/artic5693/nexroll:latest && docker restart nexroll"
```

## Unraid Paths

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `/data` | `/mnt/cache/appdata/nexroll` | DB, logs, secrets |
| `/prerolls` | `/mnt/cache/data/media/movies/preroll` | Preroll video files |

## Environment Variables

- `NEXROLL_PORT` (9393), `NEXROLL_DB_DIR` (/data), `NEXROLL_PREROLL_PATH` (/prerolls)
- `PLEX_URL`, `PLEX_TOKEN` — Plex connection (or use Plex.tv auth in UI)
- `JELLYFIN_URL`, `JELLYFIN_API_KEY` — Jellyfin connection
- `RADARR_URL`, `RADARR_API_KEY`, `SONARR_URL`, `SONARR_API_KEY` — NeX-Up trailer downloads
- `PUID` (99), `PGID` (100), `TZ` (America/New_York)

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build: Python 3.12-slim + FFmpeg + Deno |
| `entrypoint.sh` | PUID/PGID user setup, drops privileges via gosu |
| `docker-compose.yml` | Reference compose for standalone deploy |
| `nexroll-unraid-template.xml` | Unraid CA template (points to fork's GHCR image) |
| `NeXroll/backend/main.py` | FastAPI app — all API routes |
| `Plugins/` | Plugin system for extensibility |

## Fork Changes

This fork (`artic5693/NeXroll`) adds:
- PUID/PGID support in entrypoint for Unraid permission handling
- CORS restriction and API key migration (security hardening)
- GHCR CI workflow for automated image builds
- Unraid template pointing to fork's GHCR registry
