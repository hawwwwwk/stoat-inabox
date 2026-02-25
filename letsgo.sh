#!/bin/bash
set -e

DOMAIN="${DOMAIN:-localhost}"
APPDATA="${APPDATA:-/mnt/user/appdata/stoat}"

echo "[stoat-inabox] Starting up..."
echo "[stoat-inabox] Domain: $DOMAIN"
echo "[stoat-inabox] Appdata: $APPDATA"

mkdir -p "$APPDATA"

# Clone or update the stoat self-hosted repo
if [ ! -d "$APPDATA/self-hosted" ]; then
    echo "[stoat-inabox] Cloning stoat self-hosted repo..."
    git clone https://github.com/stoatchat/self-hosted "$APPDATA/self-hosted"
else
    echo "[stoat-inabox] Repo already exists, pulling latest..."
    cd "$APPDATA/self-hosted" && git pull
fi

cd "$APPDATA/self-hosted"

# Run config generator only if config doesn't already exist
if [ ! -f "$APPDATA/self-hosted/Revolt.toml" ]; then
    echo "[stoat-inabox] Generating config for $DOMAIN..."
    chmod +x ./generate_config.sh
    ./generate_config.sh "$DOMAIN"
else
    echo "[stoat-inabox] Config already exists, skipping generation."
fi

# Run the voice migration only once
if [ ! -f "$APPDATA/.voice-migration-done" ]; then
    echo "[stoat-inabox] Running voice/livekit migration..."
    chmod +x migrations/20260218-voice-config.sh
    ./migrations/20260218-voice-config.sh "$DOMAIN"
    touch "$APPDATA/.voice-migration-done"
else
    echo "[stoat-inabox] Voice migration already applied, skipping."
fi

# Bring up the full Stoat stack
echo "[stoat-inabox] Starting Stoat stack..."
docker compose -f "$APPDATA/self-hosted/compose.yml" up -d

echo "[stoat-inabox] Stoat is up! Accessible at https://$DOMAIN"
echo "[stoat-inabox] Entering monitoring loop (interval: ${CHECK_INTERVAL:-15} minutes)..."

# Monitoring loop, keeps the stack healthy
while true; do
    sleep $(( ${CHECK_INTERVAL:-15} * 60 ))
    echo "[stoat-inabox] Checking stack health..."
    docker compose -f "$APPDATA/self-hosted/compose.yml" up -d
    echo "[stoat-inabox] Health check done."
done