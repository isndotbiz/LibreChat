#!/usr/bin/env bash
set -euo pipefail

# Deploy HYDRA Enterprise to TrueNAS
# Requires: SSH access to TrueNAS, 1Password CLI, Docker

TRUENAS_HOST="${1:-100.67.89.29}"
REMOTE_DIR="${2:-/mnt/user/appdata/hydra-enterprise}"
HYDRA_SRC="${3:-/mnt/pmem/workspace/llm-security-research}"

echo "[1/5] Rendering .env from 1Password..."
./scripts/render-env-from-op.sh .env.op .env

echo "[2/5] Ensuring remote directory exists..."
ssh "$TRUENAS_HOST" "mkdir -p $REMOTE_DIR"

echo "[3/5] Syncing files to TrueNAS..."
scp .env "$TRUENAS_HOST:$REMOTE_DIR/.env"
scp librechat.yaml "$TRUENAS_HOST:$REMOTE_DIR/librechat.yaml"
scp nginx.conf "$TRUENAS_HOST:$REMOTE_DIR/nginx.conf"
scp docker-compose.hydra.yml "$TRUENAS_HOST:$REMOTE_DIR/docker-compose.hydra.yml"
scp docker-compose.truenas.yml "$TRUENAS_HOST:$REMOTE_DIR/docker-compose.truenas.yml"
scp Dockerfile.dashboard "$TRUENAS_HOST:$REMOTE_DIR/Dockerfile.dashboard"
scp init-db.sh "$TRUENAS_HOST:$REMOTE_DIR/init-db.sh"

# Sync HYDRA tool bridge
scp -r api/hydra/ "$TRUENAS_HOST:$REMOTE_DIR/api/hydra/"

echo "[4/5] Deploying with Docker Compose..."
ssh "$TRUENAS_HOST" "cd $REMOTE_DIR && \
  HYDRA_SRC=$HYDRA_SRC \
  docker compose -f docker-compose.hydra.yml -f docker-compose.truenas.yml up -d --build"

echo "[5/5] Checking health..."
sleep 5
ssh "$TRUENAS_HOST" "docker compose -f $REMOTE_DIR/docker-compose.hydra.yml ps"
ssh "$TRUENAS_HOST" "curl -sf http://localhost/health && echo ' — nginx OK'"
ssh "$TRUENAS_HOST" "curl -sf http://localhost/dashboard/ | head -1 && echo ' — dashboard OK'"

echo ""
echo "Deploy complete. Access at http://$TRUENAS_HOST/"
