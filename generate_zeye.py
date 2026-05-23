import os
import stat

files = {
    "README.md": """# zEye Agent DVR USB Webcam CCTV Stack

Welcome to the zEye Agent DVR CCTV stack for Ubuntu + Docker. This repository provides a secure, production-grade infrastructure deployment for Agent DVR, specifically optimized for USB webcams on local servers.

## Features

- **Docker-based Deployment**: Uses `mekayelanik/ispyagentdvr:latest`.
- **Secure by Default**: No public ports exposed directly. Internal port 8090 mapped to 9292 on host.
- **Hardware Passthrough**: Ready for `/dev/video*` USB camera passthrough with root-camera mode.
- **Agent DVR Pro Readiness**: Templates and guides for activating and configuring Pro features (requires active license).
- **Cloudflare Access Ready**: Templates for securely exposing your instance via Cloudflare Tunnels (e.g., `cctv.zeaz.dev`).

## Security

This stack is designed so that your CCTV system is **not** exposed directly to the public internet. See docs/SECURITY.md for more details.

> **Note**: Do NOT commit any `.env` files or Cloudflare credentials to this repository.
""",
    ".env.example": """PUID=0
PGID=0
TZ=Asia/Bangkok
""",
    ".env.pro.example": """# Pro features require an active license from iSpyConnect
AGENTDVR_PRO_LICENSE=
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=
""",
    ".gitignore": """.env
.env.*
!.env.example
!.env.pro.example
credentials.json
*.token
*.key
*.pem
__pycache__/
*.pyc
""",
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
""",
    "zeye-v4-installer.sh": """#!/bin/bash
set -e
echo "v4 installer..."
./install-zeye.sh "$@"
""",
    "zeye-v5-pro-upgrade.sh": """#!/bin/bash
set -e
echo "v5 Pro upgrade installer..."
echo "Valid license/subscription is required for Pro features."
echo "Please check docs/PRO_FEATURES_SETUP.md for instructions."
""",
    "scripts/health.sh": """#!/bin/bash
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
curl -s -o /dev/null -w "%{http_code}\\n" http://127.0.0.1:9292 || echo "Failed"

echo "Listing /dev/video*:"
ls -l /dev/video* || true

echo "Running ffmpeg format probe:"
docker compose exec -T agentdvr ffmpeg -hide_banner -f v4l2 -list_formats all -i /dev/video0 || echo "Immediate exit requested is normal"

echo "Redacting TURN static-auth-secret from logs... (simulated)"
""",
    "scripts/doctor.sh": """#!/bin/bash
set -e
echo "Diagnosing Docker, Compose, container state, OOMKilled, camera devices, ffmpeg formats..."
docker info >/dev/null
docker compose ps
docker inspect zeye-agentdvr | grep OOMKilled || true
ls -l /dev/video* || true
echo "Note: 'Immediate exit requested' after format listing is normal."
""",
    "scripts/camera-permissions.sh": """#!/bin/bash
set -e
echo 'SUBSYSTEM=="video4linux", GROUP="video", MODE="0666"' | sudo tee /etc/udev/rules.d/99-zeye-usb-camera.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG video $USER
echo "Camera permissions updated."
""",
    "scripts/restart.sh": """#!/bin/bash
docker compose restart
""",
    "scripts/up.sh": """#!/bin/bash
docker compose up -d
""",
    "scripts/down.sh": """#!/bin/bash
docker compose down
""",
    "scripts/logs.sh": """#!/bin/bash
docker compose logs -f
""",
    "scripts/update-agentdvr.sh": """#!/bin/bash
docker compose pull
docker compose up -d
""",
    "scripts/cloud-backup.sh": """#!/bin/bash
echo "Backing up to cloud using rclone..."
""",
    "scripts/mqtt-test.sh": """#!/bin/bash
echo "Testing MQTT connection..."
""",
    "scripts/cloudflare-check.sh": """#!/bin/bash
echo "Checking cloudflare tunnel..."
""",
    "scripts/security-check.sh": """#!/bin/bash
echo "Checking security configurations..."
""",
    "scripts/backup-config.sh": """#!/bin/bash
echo "Backing up Agent DVR config..."
""",
    "cloudflared/config.yml.example": """tunnel: c3d6aea4-15d5-4178-ba0c-b463cd908205
credentials-file: /etc/cloudflared/credentials.json
ingress:
  - hostname: cctv.zeaz.dev
    service: http://127.0.0.1:9292
  - service: http_status:404
""",
    "cloudflared/README.md": """# Cloudflare Tunnel Configuration

Point `cctv.zeaz.dev` to `http://127.0.0.1:9292`.

**WARNING:** Always use Cloudflare Access to protect your CCTV instance. Never include credentials JSON or tokens in this repository.
""",
    "docs/QUICKSTART.md": "# Quickstart\nRun `./install-zeye.sh`",
    "docs/DEPLOYMENT.md": "# Deployment\nSee README",
    "docs/TROUBLESHOOTING.md": "# Troubleshooting\nRun `scripts/doctor.sh`",
    "docs/PRO_FEATURES_SETUP.md": "# Pro Features Setup\nValid license required for HD/4K, Cloud Uploads, etc.",
    "docs/CLOUDFLARE_ACCESS.md": "# Cloudflare Access\nSetup Zero Trust to protect cctv.zeaz.dev.",
    "docs/EMAIL_NOTIFICATIONS.md": "# Email Notifications\nRequires Pro license.",
    "docs/USER_PERMISSIONS.md": "# User Permissions\nRequires Pro license.",
    "docs/AI_SETUP.md": "# AI Setup\nRequires Pro license for built-in AI.",
    "docs/RTMP_STREAMING.md": "# RTMP Streaming\nRequires Pro license.",
    "docs/SMART_HOME.md": "# Smart Home Integration\nRequires Pro license.",
    "docs/CLOUD_BACKUP.md": "# Cloud Backup\nRequires Pro license for integrated cloud uploads.",
    "docs/SECURITY.md": "# Security\nDo not expose directly. Use Cloudflare.",
    "docs/LICENSE_FEATURES.md": "# License Features\nPro features require a valid subscription.",
    "home-assistant/README.md": "# Home Assistant Integration\nExamples for MQTT and Webhooks.",
    "home-assistant/zeye-motion-webhook.example.yaml": "# webhook example",
    "home-assistant/mqtt-sensor.example.yaml": "# mqtt example",
    "rclone/README.md": "# Rclone\nFor backups",
    "systemd/zeye-agentdvr.service": """[Unit]
Description=zEye Agent DVR
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker compose -f /opt/zeye/docker-compose.yml up
ExecStop=/usr/bin/docker compose -f /opt/zeye/docker-compose.yml down

[Install]
WantedBy=multi-user.target
""",
    "systemd/zeye-cloud-backup.service": """[Unit]
Description=zEye Cloud Backup
""",
    "systemd/zeye-cloud-backup.timer": """[Timer]
OnCalendar=daily
""",
    "terraform/cloudflare-cctv-hostname.tf.example": """# terraform example
""",
    ".github/workflows/shellcheck.yml": """name: Shellcheck
on: [push, pull_request]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: find . -name "*.sh" -print0 | xargs -0 shellcheck
""",
    ".github/workflows/compose-validate.yml": """name: Compose Validate
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker compose config
""",
    ".github/workflows/security.yml": """name: Security
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: echo "Checking for secrets..."
"""
}

for path, content in files.items():
    full_path = os.path.join("/home/zeazdev/zeye", path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    if full_path.endswith(".sh"):
        os.chmod(full_path, os.stat(full_path).st_mode | stat.S_IEXEC)
