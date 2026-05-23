#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose logs -f --tail=200 agentdvr | sed -E 's/(--static-auth-secret )[A-Za-z0-9]+/\1<redacted>/g; s/(static-auth-secret )[A-Za-z0-9]+/\1<redacted>/g'
