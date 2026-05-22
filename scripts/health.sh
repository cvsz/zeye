#!/usr/bin/env bash
set -Eeuo pipefail

if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

PORT="${AGENTDVR_HOST_PORT:-9292}"
URL="http://127.0.0.1:${PORT}"

echo "== Docker =="
docker ps --filter name=zeye-agentdvr

echo
if curl -fsS "$URL" >/dev/null; then
  echo "[OK] Agent DVR UI reachable: $URL"
else
  echo "[FAIL] Agent DVR UI not reachable: $URL"
  exit 1
fi
