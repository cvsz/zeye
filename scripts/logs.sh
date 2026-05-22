#!/usr/bin/env bash
set -Eeuo pipefail
docker logs -f --tail=200 zeye-agentdvr
