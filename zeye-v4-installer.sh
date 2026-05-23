#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# zEye v4 Full Automated Installer / Repair
# Agent DVR USB Webcam CCTV for Ubuntu + Docker
#
# v4 goals:
# - Fix broken docker-compose.yml YAML from previous builds.
# - Keep known-good runtime: host 9292 -> container 8090.
# - Root-camera mode default for Docker/VMware V4L2.
# - Map detected /dev/video* devices.
# - Do not expose TURN UDP ports unless explicitly requested.
# - Keep cloudflared as template by default.
# ============================================================

REPO_DIR="/home/zeazdev/zeye"
OPT_DIR="/opt/zeye"
WEB_PORT="9292"
CONTAINER_PORT="8090"
PUBLIC_HOSTNAME="cctv.zeaz.dev"
TUNNEL_ID="c3d6aea4-15d5-4178-ba0c-b463cd908205"
MODE="root-camera"
ENABLE_TURN_PORTS="false"
INSTALL_CLOUDFLARED="false"
ENABLE_PUBLIC_HOSTNAME="false"
START_STACK="true"
SET_STATIC_101="false"
INTERFACE_NAME="ens33"
GATEWAY="192.168.1.1"
STATIC_IP="192.168.1.101/24"

log(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
info(){ printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; }

usage(){
cat <<EOF
zEye v4 installer / repair

Usage:
  sudo bash zeye-v4-installer.sh [options]

Options:
  --repo-dir <path>          Repo/work directory. Default: /home/zeazdev/zeye
  --opt-dir <path>           Runtime directory. Default: /opt/zeye
  --port <port>              Host web port. Default: 9292
  --hostname <host>          Cloudflare hostname. Default: cctv.zeaz.dev
  --tunnel-id <uuid>         Cloudflare tunnel UUID template
  --mode root-camera         Run Agent DVR as root in container. Default.
  --mode user-camera         Run Agent DVR as UID/GID 1000 with video group
  --enable-turn-ports        Publish UDP 3478 and 50000-50100
  --install-cloudflared      Install cloudflared package
  --enable-public-hostname   Write enabled cloudflared/config.yml
  --set-static-101           Set interface to 192.168.1.101/24
  --interface <name>         Interface for static IP. Default: ens33
  --gateway <ip>             Gateway for static IP. Default: 192.168.1.1
  --no-start                 Write/fix files only; do not restart stack
  -h, --help                 Show help

Recommended repair:
  sudo bash zeye-v4-installer.sh --repo-dir /home/zeazdev/zeye --opt-dir /opt/zeye --port 9292 --mode root-camera
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --opt-dir) OPT_DIR="$2"; shift 2 ;;
    --port) WEB_PORT="$2"; shift 2 ;;
    --hostname) PUBLIC_HOSTNAME="$2"; shift 2 ;;
    --tunnel-id) TUNNEL_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --enable-turn-ports) ENABLE_TURN_PORTS="true"; shift ;;
    --install-cloudflared) INSTALL_CLOUDFLARED="true"; shift ;;
    --enable-public-hostname) ENABLE_PUBLIC_HOSTNAME="true"; shift ;;
    --set-static-101) SET_STATIC_101="true"; shift ;;
    --interface) INTERFACE_NAME="$2"; shift 2 ;;
    --gateway) GATEWAY="$2"; shift 2 ;;
    --no-start) START_STACK="false"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1"; usage; exit 1 ;;
  esac
done

[ "${EUID:-$(id -u)}" -eq 0 ] || { fail "Run with sudo"; exit 1; }

install_packages(){
  info "Installing packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release jq usbutils v4l-utils ufw iproute2 coreutils
  log "Base packages ready"
}

install_docker(){
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    systemctl enable --now docker
    log "Docker Compose ready"
    return
  fi

  info "Installing Docker"
  install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME:-noble} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  log "Docker installed"
}

install_cloudflared(){
  [ "$INSTALL_CLOUDFLARED" = "true" ] || return 0
  if command -v cloudflared >/dev/null 2>&1; then
    log "cloudflared already installed"
    return
  fi

  info "Installing cloudflared"
  mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
    > /etc/apt/sources.list.d/cloudflared.list
  apt-get update
  apt-get install -y cloudflared
  log "cloudflared installed"
}

set_static_ip(){
  [ "$SET_STATIC_101" = "true" ] || return 0
  warn "Changing ${INTERFACE_NAME} to ${STATIC_IP}; SSH may disconnect if network is wrong."
  ip link show "$INTERFACE_NAME" >/dev/null 2>&1 || { fail "Interface not found: $INTERFACE_NAME"; ip -br link; exit 1; }
  cp -a /etc/netplan "/root/netplan-backup-$(date +%Y%m%d-%H%M%S)"
  cat > /etc/netplan/99-zeye-static.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ${INTERFACE_NAME}:
      dhcp4: false
      addresses:
        - ${STATIC_IP}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
EOF
  netplan generate
  netplan apply
  ip -br addr show "$INTERFACE_NAME" || true
}

prepare_dirs(){
  info "Preparing directories"
  mkdir -p "$REPO_DIR"/{scripts,cloudflared,systemd,terraform,docs}
  mkdir -p "$OPT_DIR"/{config,media,commands,backups,logs}
  chmod -R 777 "$OPT_DIR/config" "$OPT_DIR/media" "$OPT_DIR/commands"
  log "Directories ready"
}

camera_permissions(){
  info "Applying camera permissions"
  cat > /etc/udev/rules.d/99-zeye-video.rules <<'EOF'
KERNEL=="video[0-9]*", GROUP="video", MODE="0666"
SUBSYSTEM=="video4linux", GROUP="video", MODE="0666"
EOF
  udevadm control --reload-rules || true
  udevadm trigger || true
  chmod 666 /dev/video* 2>/dev/null || true
  usermod -aG video zeazdev 2>/dev/null || true
  ls -l /dev/video* 2>/dev/null || warn "No /dev/video* detected"
}

write_env(){
  cat > "$REPO_DIR/.env" <<EOF
APP=zeye
TZ=Asia/Bangkok
WEB_PORT=${WEB_PORT}
CONTAINER_PORT=${CONTAINER_PORT}
PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
TUNNEL_ID=${TUNNEL_ID}
MODE=${MODE}
ENABLE_TURN_PORTS=${ENABLE_TURN_PORTS}
OPT_DIR=${OPT_DIR}
EOF

  cat > "$REPO_DIR/.env.example" <<EOF
APP=zeye
TZ=Asia/Bangkok
WEB_PORT=9292
CONTAINER_PORT=8090
PUBLIC_HOSTNAME=cctv.zeaz.dev
TUNNEL_ID=c3d6aea4-15d5-4178-ba0c-b463cd908205
MODE=root-camera
ENABLE_TURN_PORTS=false
OPT_DIR=/opt/zeye
EOF
}

write_compose(){
  info "Writing clean docker-compose.yml"
  [ -f "$REPO_DIR/docker-compose.yml" ] && cp -a "$REPO_DIR/docker-compose.yml" "$REPO_DIR/docker-compose.yml.bak.$(date +%Y%m%d-%H%M%S)" || true

  local puid="0"
  local pgid="0"
  if [ "$MODE" = "user-camera" ]; then
    puid="1000"
    pgid="1000"
  fi

  {
    echo "services:"
    echo "  agentdvr:"
    echo "    image: mekayelanik/ispyagentdvr:latest"
    echo "    container_name: zeye-agentdvr"
    echo "    restart: unless-stopped"
    echo "    privileged: true"
    echo "    environment:"
    echo "      PUID: \"${puid}\""
    echo "      PGID: \"${pgid}\""
    echo "      TZ: \"Asia/Bangkok\""
    echo "      AGENTDVR_WEBUI_PORT: \"${CONTAINER_PORT}\""
    echo "    ports:"
    echo "      - \"${WEB_PORT}:${CONTAINER_PORT}\""
    if [ "$ENABLE_TURN_PORTS" = "true" ]; then
      echo "      - \"3478:3478/udp\""
      echo "      - \"50000-50100:50000-50100/udp\""
    fi
    echo "    devices:"
    if ls /dev/video* >/dev/null 2>&1; then
      for d in /dev/video*; do
        echo "      - \"${d}:${d}\""
      done
    else
      echo "      - \"/dev/video0:/dev/video0\""
    fi
    echo "    device_cgroup_rules:"
    echo "      - \"c 81:* rmw\""
    if [ "$MODE" = "user-camera" ]; then
      local video_gid
      video_gid="$(getent group video | cut -d: -f3 || true)"
      echo "    group_add:"
      echo "      - \"${video_gid:-44}\""
    fi
    echo "    volumes:"
    echo "      - \"${OPT_DIR}/config:/AgentDVR/Media/XML\""
    echo "      - \"${OPT_DIR}/media:/AgentDVR/Media/WebServerRoot/Media\""
    echo "      - \"${OPT_DIR}/commands:/AgentDVR/Commands\""
    echo ""
    echo "networks:"
    echo "  default:"
    echo "    name: zeye_default"
  } > "$REPO_DIR/docker-compose.yml"

  cd "$REPO_DIR"
  docker compose config >/tmp/zeye-v4-compose-check.yml
  rm -f /tmp/zeye-v4-compose-check.yml
  log "Compose YAML valid"
}

write_scripts(){
  info "Writing helper scripts"

  cat > "$REPO_DIR/scripts/health.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a
PORT="${WEB_PORT:-9292}"
TMP_FILE="$(mktemp /tmp/zeye-compose-health.XXXXXX.yml)"
trap 'rm -f "$TMP_FILE"' EXIT

echo "== zEye health =="
echo
echo "== Host IPs =="
hostname -I || true
ip -br addr || true

echo
echo "== Compose config check =="
if docker compose config > "$TMP_FILE"; then echo "OK: compose YAML valid"; else echo "FAIL: compose YAML invalid"; fi

echo
echo "== Docker =="
docker compose ps || true
docker ps -a --filter name=zeye-agentdvr || true

echo
echo "== Port listening =="
ss -ltnp | grep ":${PORT}" || true

echo
echo "== HTTP GET =="
for url in "http://127.0.0.1:${PORT}" $(hostname -I | awk -v p="$PORT" '{for(i=1;i<=NF;i++) if ($i !~ /^172\./ && $i !~ /:/) print "http://"$i":"p}'); do
  if curl -fsS --max-time 10 "$url/" >/dev/null; then echo "OK: $url"; else echo "WARN: failed $url"; fi
done

echo
echo "== USB video =="
ls -l /dev/video* 2>/dev/null || echo "No /dev/video* found"

echo
echo "== Container camera probe =="
docker exec zeye-agentdvr sh -lc 'id; ls -l /dev/video* 2>/dev/null || true; ffmpeg -hide_banner -f v4l2 -list_formats all -i /dev/video0' 2>&1 | tail -120 || true
echo "Note: ffmpeg format-list command often ends with Immediate exit requested after listing formats; this is OK."

echo
echo "== Recent logs redacted =="
docker compose logs --tail=140 agentdvr 2>/dev/null | sed -E 's/(--static-auth-secret )[A-Za-z0-9]+/\1<redacted>/g; s/(static-auth-secret )[A-Za-z0-9]+/\1<redacted>/g' || true
EOF

  cat > "$REPO_DIR/scripts/doctor.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

echo "== zEye doctor =="
echo
echo "Docker:"
docker version --format 'Client={{.Client.Version}} Server={{.Server.Version}}' || true
docker compose version || true

echo
echo "Compose:"
docker compose config >/tmp/zeye-doctor-compose.yml && echo OK || echo FAIL
rm -f /tmp/zeye-doctor-compose.yml

echo
echo "Container:"
docker inspect zeye-agentdvr --format 'Status={{.State.Status}} Exit={{.State.ExitCode}} Error={{.State.Error}} OOM={{.State.OOMKilled}}' 2>/dev/null || true

echo
echo "Host video devices:"
ls -l /dev/video* 2>/dev/null || true
v4l2-ctl --list-devices 2>/dev/null || true

echo
echo "Container video probe:"
docker exec zeye-agentdvr sh -lc '
id
ls -l /dev/video* 2>/dev/null || true
for d in /dev/video*; do
  [ -e "$d" ] || continue
  echo "===$d==="
  ffmpeg -hide_banner -f v4l2 -list_formats all -i "$d" 2>&1 | head -80 || true
done
' || true

echo
echo "Recommended Agent DVR UI:"
echo "  Video Source -> Local Device -> /dev/video0"
echo "  Advanced -> Decoder CPU, GPU Decoder Default, VLC Options blank"
EOF

  cat > "$REPO_DIR/scripts/camera-permissions.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
sudo tee /etc/udev/rules.d/99-zeye-video.rules >/dev/null <<'RULE'
KERNEL=="video[0-9]*", GROUP="video", MODE="0666"
SUBSYSTEM=="video4linux", GROUP="video", MODE="0666"
RULE
sudo udevadm control --reload-rules || true
sudo udevadm trigger || true
sudo chmod 666 /dev/video* 2>/dev/null || true
sudo usermod -aG video "${USER:-zeazdev}" 2>/dev/null || true
ls -l /dev/video* 2>/dev/null || true
EOF

  cat > "$REPO_DIR/scripts/restart.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose config >/tmp/zeye-restart-compose.yml
rm -f /tmp/zeye-restart-compose.yml
docker compose down --remove-orphans || true
docker rm -f zeye-agentdvr 2>/dev/null || true
docker compose up -d
sleep 75
docker compose ps
bash scripts/health.sh
EOF

  cat > "$REPO_DIR/scripts/up.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose config >/tmp/zeye-up-compose.yml
rm -f /tmp/zeye-up-compose.yml
docker compose pull
docker compose up -d
docker compose ps
EOF

  cat > "$REPO_DIR/scripts/down.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose down
EOF

  cat > "$REPO_DIR/scripts/logs.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
docker compose logs -f --tail=200 agentdvr | sed -E 's/(--static-auth-secret )[A-Za-z0-9]+/\1<redacted>/g; s/(static-auth-secret )[A-Za-z0-9]+/\1<redacted>/g'
EOF

  chmod +x "$REPO_DIR/scripts/"*.sh
  log "Scripts ready"
}

write_cloudflared(){
  cat > "$REPO_DIR/cloudflared/config.yml.example" <<EOF
# zEye Cloudflare Tunnel template
# Do not commit tunnel credentials or tokens.
#
# tunnel: ${TUNNEL_ID}
# credentials-file: /etc/cloudflared/${TUNNEL_ID}.json
#
# ingress:
#   - hostname: ${PUBLIC_HOSTNAME}
#     service: http://127.0.0.1:${WEB_PORT}
#   - service: http_status:404
EOF

  if [ "$ENABLE_PUBLIC_HOSTNAME" = "true" ]; then
    cat > "$REPO_DIR/cloudflared/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${PUBLIC_HOSTNAME}
    service: http://127.0.0.1:${WEB_PORT}
  - service: http_status:404
EOF
    warn "Enabled Cloudflare config written. Use Cloudflare Access/auth."
  fi
}

write_systemd(){
  cat > "$REPO_DIR/systemd/zeye-agentdvr.service" <<EOF
[Unit]
Description=zEye Agent DVR Docker Compose Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${REPO_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
  cp "$REPO_DIR/systemd/zeye-agentdvr.service" /etc/systemd/system/zeye-agentdvr.service
  systemctl daemon-reload
  systemctl enable zeye-agentdvr.service
  log "systemd enabled"
}

write_docs(){
  cat > "$REPO_DIR/README.md" <<EOF
# zEye

Agent DVR USB webcam CCTV stack for Ubuntu + Docker.

## Working URLs

- Local: http://127.0.0.1:${WEB_PORT}
- LAN: http://192.168.1.104:${WEB_PORT} or http://192.168.1.100:${WEB_PORT}
- Cloudflare origin: http://127.0.0.1:${WEB_PORT}

## Agent DVR UI

Use:

\`\`\`text
Video Source:
  Source Type = Local Device
  Device      = /dev/video0

Advanced:
  Decoder     = CPU
  GPU Decoder = Default
  VLC Options = blank
\`\`\`

## Notes

\`ffmpeg -list_formats\` can end with "Immediate exit requested" after listing MJPEG/YUYV formats. That is normal.
EOF

  cat > "$REPO_DIR/docs/REVIEW.md" <<'EOF'
# zEye v4 Review

The observed deployment is functional but docker-compose.yml became syntactically invalid in v3. v4 fixes this by writing docker-compose.yml line-by-line.

Known-good facts:
- Agent DVR container runs healthy.
- Agent DVR internal UI listens on 8090.
- Host 9292 -> container 8090 is correct.
- /dev/video0 supports MJPEG and YUYV up to 1280x720.
- /dev/video2 supports MJPEG/YUYV with more formats.
- /dev/video1 and /dev/video3 are metadata/unsupported endpoints.
- CPU decoder is recommended in VMware/Docker.
- Root-camera mode is the stable working mode.
EOF

  cat > "$REPO_DIR/.gitignore" <<'EOF'
.env
*.bak.*
*.log
cloudflared/*.json
cloudflared/*.pem
cloudflared/*.cert
.cloudflared/
EOF

  cat > "$REPO_DIR/terraform/cloudflare-cctv-hostname.tf.example" <<EOF
# Example only.
# Recommended Cloudflare Tunnel ingress:
# ${PUBLIC_HOSTNAME} -> http://127.0.0.1:${WEB_PORT}
EOF
}

firewall(){
  if command -v ufw >/dev/null 2>&1 && ufw status | grep -qi "Status: active"; then
    ufw allow "${WEB_PORT}/tcp" comment "zEye Agent DVR" || true
    if [ "$ENABLE_TURN_PORTS" = "true" ]; then
      ufw allow 3478/udp comment "zEye TURN" || true
      ufw allow 50000:50100/udp comment "zEye TURN relay" || true
    fi
    log "UFW updated"
  else
    warn "UFW inactive; no firewall change"
  fi
}

start_stack(){
  [ "$START_STACK" = "true" ] || { warn "Skipping start because --no-start was set"; return 0; }
  info "Starting stack"
  cd "$REPO_DIR"
  docker compose down --remove-orphans || true
  docker rm -f zeye-agentdvr 2>/dev/null || true
  docker compose pull
  docker compose up -d
  sleep 75
  docker compose ps
  bash scripts/health.sh || true
}

summary(){
  log "zEye v4 complete"
  echo
  echo "Open:"
  for ip in $(hostname -I 2>/dev/null || true); do
    case "$ip" in
      172.*|127.*|*:* ) continue ;;
      *) echo "  http://${ip}:${WEB_PORT}" ;;
    esac
  done
  echo "  http://127.0.0.1:${WEB_PORT}"
  echo
  echo "Cloudflare origin: http://127.0.0.1:${WEB_PORT}"
}

main(){
  install_packages
  install_docker
  install_cloudflared
  set_static_ip
  prepare_dirs
  camera_permissions
  write_env
  write_compose
  write_scripts
  write_cloudflared
  write_systemd
  write_docs
  firewall
  start_stack
  summary
}

main "$@"
