#!/bin/bash
set -e
echo "Starting zEye Agent DVR setup..."
mkdir -p /opt/zeye/{config,media,commands}
cp .env.example .env

ENABLE_TURN=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --enable-turn-ports) ENABLE_TURN=true ;;
    esac
    shift
done

if [ "$ENABLE_TURN" = true ]; then
    echo "Enabling TURN ports..."
    cat << 'EOF' > docker-compose.override.yml
services:
  agentdvr:
    ports:
      - "3478:3478/udp"
      - "50000-50100:50000-50100/udp"
EOF
fi

echo "Done. Run 'docker compose up -d' to start."
