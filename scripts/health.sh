#!/bin/bash
set -e

# Validate compose with mktemp
temp_dir=$(mktemp -d)
cp docker-compose.yml "$temp_dir/"
if [ -f docker-compose.override.yml ]; then
    cp docker-compose.override.yml "$temp_dir/"
fi
docker compose -f "$temp_dir/docker-compose.yml" config > /dev/null
rm -rf "$temp_dir"

echo "Host IPs:"
hostname -I

echo "Docker Compose PS:"
docker compose ps

echo "Testing HTTP on localhost:"
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:9292 || echo "Failed"

echo "Listing /dev/video*:"
ls -l /dev/video* || true

echo "Running ffmpeg format probe:"
docker compose exec -T agentdvr ffmpeg -hide_banner -f v4l2 -list_formats all -i /dev/video0 || echo "Immediate exit requested is normal"

echo "Redacting TURN static-auth-secret from logs... (simulated)"
