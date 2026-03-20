#!/bin/sh
set -e

PUID="${PUID:-99}"
PGID="${PGID:-100}"

echo "NeXroll: Setting up user nexroll with UID=${PUID} GID=${PGID}"

# Create group if it doesn't exist
if ! getent group nexroll >/dev/null 2>&1; then
    addgroup --gid "$PGID" nexroll
fi

# Create user if it doesn't exist
if ! getent passwd nexroll >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" --uid "$PUID" --ingroup nexroll --home /app nexroll
fi

# Ensure /data is owned by nexroll
chown -R "$PUID:$PGID" /data

# Ensure Deno cache dir exists and is writable
mkdir -p /home/nexroll/.cache
chown -R "$PUID:$PGID" /home/nexroll/.cache 2>/dev/null || true

# Drop privileges and exec uvicorn
exec gosu nexroll uvicorn backend.main:app --host 0.0.0.0 --port "${NEXROLL_PORT:-9393}"
