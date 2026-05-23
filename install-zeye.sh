#!/bin/bash
set -e

echo "Starting hardened zEye Agent DVR setup..."

NO_START=false
ENABLE_TURN=false
STATIC_101=false

for arg in "$@"; do
    case $arg in
        --no-start) NO_START=true ;;
        --enable-turn-ports) ENABLE_TURN=true ;;
        --set-static-101) STATIC_101=true ;;
    esac
done

echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y curl jq v4l-utils usbutils ufw iproute2

if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker CE..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm -f get-docker.sh
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "Installing Docker Compose Plugin..."
    sudo apt-get install -y docker-compose-plugin || true
fi

echo "Creating runtime directories..."
sudo mkdir -p /opt/zeye/config /opt/zeye/media /opt/zeye/commands
sudo chmod 777 /opt/zeye/config /opt/zeye/media /opt/zeye/commands

echo "Detecting video devices..."
if ls /dev/video* 1> /dev/null 2>&1; then
    ls -l /dev/video*
else
    echo "No /dev/video* devices found!"
fi

echo "Generating docker-compose.yml..."
if [ -f docker-compose.yml ]; then
    cp docker-compose.yml docker-compose.yml.bak
fi

# Write docker-compose.yml line-by-line
{
    echo "services:"
    echo "  agentdvr:"
    echo "    image: mekayelanik/ispyagentdvr:latest"
    echo "    container_name: zeye-agentdvr"
    echo "    restart: unless-stopped"
    echo "    privileged: true"
    echo "    environment:"
    echo "      PUID: "0""
    echo "      PGID: "0""
    echo "      TZ: "Asia/Bangkok""
    echo "      AGENTDVR_WEBUI_PORT: "8090""
    echo "    ports:"
    echo "      - "9292:8090""
    if [ "$ENABLE_TURN" = true ]; then
        echo "      - "3478:3478/udp""
        echo "      - "50000-50100:50000-50100/udp""
    fi
    echo "    devices:"
    for dev in /dev/video*; do
        if [ -c "$dev" ]; then
            echo "      - "${dev}:${dev}""
        fi
    done
    echo "    device_cgroup_rules:"
    echo "      - "c 81:* rmw""
    echo "    volumes:"
    echo "      - "/opt/zeye/config:/AgentDVR/Media/XML""
    echo "      - "/opt/zeye/media:/AgentDVR/Media/WebServerRoot/Media""
    echo "      - "/opt/zeye/commands:/AgentDVR/Commands""
    echo ""
    echo "networks:"
    echo "  default:"
    echo "    name: zeye_default"
    if [ "$STATIC_101" = true ]; then
        echo "    # Placeholder for static 101 config"
    fi
} > docker-compose.yml

echo "Validating docker compose config..."
if ! docker compose config > /dev/null; then
    echo "Docker compose validation failed. Restoring backup..."
    if [ -f docker-compose.yml.bak ]; then
        mv docker-compose.yml.bak docker-compose.yml
    fi
    exit 1
fi

if [ "$NO_START" = false ]; then
    echo "Starting container..."
    docker compose up -d
else
    echo "Skipping container start due to --no-start flag."
fi

echo "Setup complete."
