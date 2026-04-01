#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST="${1:-46.224.100.66}"
USER_NAME="${2:-root}"
REMOTE_DIR="${3:-/root/Workspace/librechat-hydra}"
BRANCH="${4:-hydra-enterprise}"
SSH_TARGET="${USER_NAME}@${HOST}"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "error: $ROOT_DIR/.env not found" >&2
  echo "hint: run ./scripts/render-env-from-op.sh first" >&2
  exit 1
fi

echo "[1/5] Sync branch on VPS"
ssh "$SSH_TARGET" "mkdir -p /root/Workspace && if [ ! -d '$REMOTE_DIR/.git' ]; then git clone https://github.com/isndotbiz/LibreChat '$REMOTE_DIR'; fi && cd '$REMOTE_DIR' && git fetch origin && git checkout '$BRANCH' && git pull --ff-only origin '$BRANCH'"

echo "[2/5] Upload runtime config"
scp "$ROOT_DIR/.env" "$SSH_TARGET:$REMOTE_DIR/.env"
scp "$ROOT_DIR/librechat.yaml" "$SSH_TARGET:$REMOTE_DIR/librechat.yaml"
scp "$ROOT_DIR/nginx.conf" "$SSH_TARGET:$REMOTE_DIR/nginx.conf"
scp "$ROOT_DIR/init-db.sh" "$SSH_TARGET:$REMOTE_DIR/init-db.sh"

echo "[3/5] Deploy containers"
ssh "$SSH_TARGET" "cd '$REMOTE_DIR' && docker compose -f docker-compose.hydra.yml down && docker compose -f docker-compose.hydra.yml up -d --build"

echo "[4/5] Container status"
ssh "$SSH_TARGET" "cd '$REMOTE_DIR' && docker compose -f docker-compose.hydra.yml ps"

echo "[5/5] Health checks"
ssh "$SSH_TARGET" "curl -sS http://127.0.0.1/health"
curl -sS "http://$HOST/health"

echo "deployment complete: http://$HOST"
