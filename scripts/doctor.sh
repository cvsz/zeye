#!/bin/bash
set -e
echo "Diagnosing Docker, Compose, container state, OOMKilled, camera devices, ffmpeg formats..."
docker info >/dev/null
docker compose ps
docker inspect zeye-agentdvr | grep OOMKilled || true
ls -l /dev/video* || true
echo "Note: 'Immediate exit requested' after format listing is normal."
