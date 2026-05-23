#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
: "${WEB_PORT:=9292}"
: "${CONTAINER_PORT:=8090}"
: "${USB_DEVICE:=/dev/video0}"
: "${AGENTDVR_IMAGE:=mekayelanik/ispyagentdvr:latest}"
: "${TZ:=Asia/Bangkok}"
: "${OPT_DIR:=/opt/zeye}"

if [ -e "$USB_DEVICE" ]; then
  DEVICE_BLOCK="    devices:
      - \"${USB_DEVICE}:/dev/video0\"
    group_add:
      - video"
else
  DEVICE_BLOCK="    # USB camera not found. Connect it to host/VM, then rerun scripts/rebuild-compose.sh
    # devices:
    #   - \"${USB_DEVICE}:/dev/video0\"
    # group_add:
    #   - video"
fi

cat > docker-compose.yml <<COMPOSE
services:
  agentdvr:
    image: "${AGENTDVR_IMAGE}"
    container_name: zeye-agentdvr
    restart: unless-stopped
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: "${TZ}"
      AGENTDVR_WEBUI_PORT: "${CONTAINER_PORT}"
    ports:
      - "${WEB_PORT}:${CONTAINER_PORT}"
      - "3478:3478/udp"
      - "50000-50100:50000-50100/udp"
    volumes:
      - "${OPT_DIR}/config:/AgentDVR/Media/XML"
      - "${OPT_DIR}/media:/AgentDVR/Media/WebServerRoot/Media"
      - "${OPT_DIR}/commands:/AgentDVR/Commands"
${DEVICE_BLOCK}
    security_opt:
      - no-new-privileges:true
COMPOSE

docker compose config >/tmp/zeye-compose.rendered.yml
echo "[OK] docker-compose.yml rebuilt and validated"
