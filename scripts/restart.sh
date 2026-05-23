#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose config >/tmp/zeye-restart-compose.yml
rm -f /tmp/zeye-restart-compose.yml
docker compose down --remove-orphans || true
docker rm -f zeye-agentdvr 2>/dev/null || true
docker compose up -d
sleep 75
docker compose ps
bash scripts/health.sh
