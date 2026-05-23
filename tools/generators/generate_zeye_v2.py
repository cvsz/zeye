import os
import stat

files = {
    "docker-compose.yml": """services:
  agentdvr:
    image: mekayelanik/ispyagentdvr:latest
    container_name: zeye-agentdvr
    restart: unless-stopped
    privileged: true
    environment:
      PUID: "0"
      PGID: "0"
      TZ: "Asia/Bangkok"
      AGENTDVR_WEBUI_PORT: "8090"
    ports:
      - "9292:8090"
    devices:
      - "/dev/video0:/dev/video0"
      - "/dev/video1:/dev/video1"
      - "/dev/video2:/dev/video2"
      - "/dev/video3:/dev/video3"
    device_cgroup_rules:
      - "c 81:* rmw"
    volumes:
      - "/opt/zeye/config:/AgentDVR/Media/XML"
      - "/opt/zeye/media:/AgentDVR/Media/WebServerRoot/Media"
      - "/opt/zeye/commands:/AgentDVR/Commands"

networks:
  default:
    name: zeye_default
""",
    "install-zeye.sh": """#!/bin/bash
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
    echo "      PUID: \"0\""
    echo "      PGID: \"0\""
    echo "      TZ: \"Asia/Bangkok\""
    echo "      AGENTDVR_WEBUI_PORT: \"8090\""
    echo "    ports:"
    echo "      - \"9292:8090\""
    if [ "$ENABLE_TURN" = true ]; then
        echo "      - \"3478:3478/udp\""
        echo "      - \"50000-50100:50000-50100/udp\""
    fi
    echo "    devices:"
    for dev in /dev/video*; do
        if [ -c "$dev" ]; then
            echo "      - \"${dev}:${dev}\""
        fi
    done
    echo "    device_cgroup_rules:"
    echo "      - \"c 81:* rmw\""
    echo "    volumes:"
    echo "      - \"/opt/zeye/config:/AgentDVR/Media/XML\""
    echo "      - \"/opt/zeye/media:/AgentDVR/Media/WebServerRoot/Media\""
    echo "      - \"/opt/zeye/commands:/AgentDVR/Commands\""
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
""",
    "zeye-v4-installer.sh": """#!/bin/bash
set -e
echo "Invoking v4 install-zeye.sh..."
./install-zeye.sh "$@"
""",
    "scripts/health.sh": """#!/bin/bash
set -e

temp_dir=$(mktemp -d)
cp docker-compose.yml "$temp_dir/"
if docker compose -f "$temp_dir/docker-compose.yml" config > "$temp_dir/config_out" 2>&1; then
    sed 's/static-auth-secret.*/static-auth-secret: <REDACTED>/g' "$temp_dir/config_out"
else
    cat "$temp_dir/config_out"
    rm -rf "$temp_dir"
    exit 1
fi
rm -rf "$temp_dir"

echo "Host IPs:"
hostname -I || ip addr show

echo "Testing HTTP on localhost:"
curl -s -o /dev/null -w "127.0.0.1 HTTP %{http_code}\\n" http://127.0.0.1:9292 || true

echo "Testing HTTP on LAN:"
for ip in $(hostname -I); do
    curl -m 2 -s -o /dev/null -w "$ip HTTP %{http_code}\\n" http://$ip:9292 || true
done

echo "Listing /dev/video*:"
ls -l /dev/video* || true

echo "Camera probe:"
if docker compose ps | grep -q "zeye-agentdvr"; then
    probe_output=$(docker compose exec -T agentdvr ffmpeg -hide_banner -f v4l2 -list_formats all -i /dev/video0 2>&1 || true)
    echo "$probe_output"
    if echo "$probe_output" | grep -q "Immediate exit requested"; then
        echo "Format probe completed normally (Immediate exit requested is expected)."
    fi
fi
""",
    "scripts/doctor.sh": """#!/bin/bash
set -e
docker info >/dev/null
docker compose ps || true
docker inspect zeye-agentdvr | grep -i "OOMKilled" || true
ls -l /dev/video* || true
echo "Doctor checks complete."
""",
    "scripts/restart.sh": """#!/bin/bash
set -e
docker compose restart
""",
    "scripts/camera-permissions.sh": """#!/bin/bash
set -e
echo 'SUBSYSTEM=="video4linux", GROUP="video", MODE="0666"' | sudo tee /etc/udev/rules.d/99-zeye-usb-camera.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG video $USER || true
echo "Camera permissions updated."
"""
}

for path, content in files.items():
    full_path = os.path.join("/home/zeazdev/zeye", path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    if full_path.endswith(".sh"):
        os.chmod(full_path, os.stat(full_path).st_mode | stat.S_IEXEC)
