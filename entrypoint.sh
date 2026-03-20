#!/bin/sh
set -e

PUID="${PUID:-99}"
PGID="${PGID:-100}"

echo "NeXroll: Setting up user nexroll with UID=${PUID} GID=${PGID}"

# Get or create group with the requested GID
GROUP_NAME=$(getent group "$PGID" 2>/dev/null | cut -d: -f1)
if [ -z "$GROUP_NAME" ]; then
    addgroup --gid "$PGID" nexroll
    GROUP_NAME="nexroll"
fi

# Create user if no user with this UID exists
if ! getent passwd "$PUID" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" --uid "$PUID" --ingroup "$GROUP_NAME" --home /app --no-create-home nexroll
fi

# Get the username for this UID (may not be "nexroll" if it already existed)
USER_NAME=$(getent passwd "$PUID" 2>/dev/null | cut -d: -f1)

# Ensure /data is owned by the target UID:GID
chown -R "$PUID:$PGID" /data

# Ensure Deno cache dir exists and is writable
CACHE_DIR="/tmp/nexroll-cache"
mkdir -p "$CACHE_DIR"
chown -R "$PUID:$PGID" "$CACHE_DIR"
export XDG_CACHE_HOME="$CACHE_DIR"

# Drop privileges and exec uvicorn
exec gosu "$USER_NAME" uvicorn backend.main:app --host 0.0.0.0 --port "${NEXROLL_PORT:-9393}"
