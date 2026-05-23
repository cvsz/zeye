#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose config >/tmp/zeye-up-compose.yml
rm -f /tmp/zeye-up-compose.yml
docker compose pull
docker compose up -d
docker compose ps
