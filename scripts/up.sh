#!/usr/bin/env bash
set -Eeuo pipefail

[ -f .env ] || cp .env.example .env

docker compose up -d

echo "[OK] zEye Agent DVR started"
echo "Local: http://127.0.0.1:${AGENTDVR_HOST_PORT:-9292}"
if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi
echo "LAN:   http://${LAN_HOST:-192.168.1.101}:${AGENTDVR_HOST_PORT:-9292}"
