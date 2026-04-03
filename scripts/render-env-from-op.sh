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

# Read the secure-note reference from the template before injection.
SECRETS_REF="$(grep -E '^HYDRA_SECRETS_REF=' "$TEMPLATE_FILE" | sed -E 's/^HYDRA_SECRETS_REF=//')"

op inject --force -i "$TEMPLATE_FILE" -o "$TMP_FILE"
sed -i.bak -E '/^HYDRA_SECRETS_REF=/d' "$TMP_FILE" && rm -f "$TMP_FILE.bak"

# Optional: hydrate additional key=value pairs from a secure note reference.
# Expected format in template: HYDRA_SECRETS_REF=op://Vault/Item/notesPlain
if [[ -n "${SECRETS_REF:-}" ]] && [[ "$SECRETS_REF" == op://* ]]; then
  NOTE_CONTENT="$(op read "$SECRETS_REF" 2>/dev/null || true)"
  if [[ -n "${NOTE_CONTENT:-}" ]]; then
    while IFS= read -r line; do
      line="${line//$'\r'/}"
      line="${line#$'\ufeff'}"
      line="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      if [[ "$line" =~ ^[A-Z0-9_]+= ]]; then
        key="${line%%=*}"
        grep -q "^${key}=" "$TMP_FILE" && sed -i.bak -E "s|^${key}=.*$|${line}|" "$TMP_FILE" || echo "$line" >> "$TMP_FILE"
      fi
    done <<< "$NOTE_CONTENT"
    rm -f "$TMP_FILE.bak"
  fi
fi

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
