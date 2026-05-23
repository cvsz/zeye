#!/bin/bash
set -e
echo "Backing up docker-compose.yml before update..."
cp docker-compose.yml "docker-compose.yml.backup-$(date +%s)" || true

echo "Pulling latest agentdvr image..."
docker compose pull agentdvr

echo "Restarting container to apply updates..."
docker compose up -d

echo "Update complete."
