# syntax=docker/dockerfile:1

# --- Backend runtime stage ---
FROM python:3.12-slim

ARG APP_VERSION=dev
ARG VERSION=dev
LABEL org.opencontainers.image.title="NeXroll" \
      org.opencontainers.image.description="NeXroll preroll management system" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="MIT"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NEXROLL_PORT=9393 \
    NEXROLL_DB_DIR=/data \
    NEXROLL_PREROLL_PATH=/data/prerolls \
    NEXROLL_SECRETS_DIR=/data \
    PLEX_URL="" \
    JELLYFIN_URL="" \
    RADARR_URL="" \
    SONARR_URL="" \
    PUID=99 \
    PGID=100 \
    TZ=UTC

# Install runtime deps + build deps (removed after pip install)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        curl \
        unzip \
        tzdata \
        gosu \
        build-essential \
        rustc \
        cargo \
        pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Install pinned Deno binary with checksum verification (required for yt-dlp YouTube extraction)
ARG DENO_VERSION=2.7.7
ARG DENO_SHA256=0cd918870657ccc3d96ac682290e894dda374e2a742424aae9118b258a6cf7a3
RUN curl -fsSL -o /tmp/deno.zip \
        "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" && \
    echo "${DENO_SHA256}  /tmp/deno.zip" | sha256sum -c - && \
    unzip -o /tmp/deno.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/deno && \
    rm /tmp/deno.zip

WORKDIR /app/NeXroll

# Install Python deps, then remove build toolchain to shrink image
COPY requirements.txt /app/NeXroll/requirements.txt
RUN pip install --no-cache-dir -r /app/NeXroll/requirements.txt && \
    apt-get purge -y --auto-remove build-essential rustc cargo pkg-config && \
    rm -rf /var/lib/apt/lists/* /root/.cargo /root/.rustup /tmp/*

# Copy backend
COPY NeXroll/backend /app/NeXroll/backend

# Copy version.py
COPY NeXroll/version.py /app/NeXroll/version.py

# Copy CHANGELOG
COPY NeXroll/CHANGELOG.md /app/NeXroll/CHANGELOG.md

# Copy audio assets for Coming Soon generator
COPY docs/lefty-blue-wednesday-main-version-36162-02-38.mp3 /app/docs/lefty-blue-wednesday-main-version-36162-02-38.mp3

# Copy pre-built frontend assets (built locally before Docker build)
COPY NeXroll/frontend/build /app/NeXroll/frontend/build

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Prepare persistent data volume
RUN mkdir -p /data /data/prerolls

VOLUME ["/data"]

EXPOSE 9393

# Healthcheck: FastAPI health endpoint
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsS http://localhost:${NEXROLL_PORT:-9393}/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
