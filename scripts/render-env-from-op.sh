#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="${1:-$ROOT_DIR/.env.op}"
OUTPUT_FILE="${2:-$ROOT_DIR/.env}"

if ! command -v op >/dev/null 2>&1; then
  echo "error: 1Password CLI ('op') is not installed" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "error: template not found: $TEMPLATE_FILE" >&2
  echo "hint: copy env.op.example to .env.op and adjust secret references" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

op inject --force -i "$TEMPLATE_FILE" -o "$TMP_FILE"

if ! grep -q '^JWT_SECRET=' "$TMP_FILE"; then
  echo "JWT_SECRET=$(openssl rand -hex 32)" >> "$TMP_FILE"
fi
if ! grep -q '^CREDS_KEY=' "$TMP_FILE"; then
  echo "CREDS_KEY=$(openssl rand -hex 32)" >> "$TMP_FILE"
fi
if ! grep -q '^CREDS_IV=' "$TMP_FILE"; then
  echo "CREDS_IV=$(openssl rand -hex 16)" >> "$TMP_FILE"
fi

install -m 600 "$TMP_FILE" "$OUTPUT_FILE"
echo "rendered $OUTPUT_FILE from $TEMPLATE_FILE"
