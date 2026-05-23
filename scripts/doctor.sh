#!/bin/bash
set -e
docker info >/dev/null
docker compose ps || true
docker inspect zeye-agentdvr | grep -i "OOMKilled" || true
ls -l /dev/video* || true
echo "Doctor checks complete."
