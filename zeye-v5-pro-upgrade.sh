#!/usr/bin/env bash
set -Eeuo pipefail

# zEye v5 Pro Upgrade Prep
# Prepares legal/licensed Agent DVR premium workflows.
# It does NOT bypass, unlock, crack, or replace any iSpyConnect license.

REPO_DIR="${REPO_DIR:-/home/zeazdev/zeye}"
OPT_DIR="${OPT_DIR:-/opt/zeye}"
WEB_PORT="${WEB_PORT:-9292}"
CONTAINER_PORT="${CONTAINER_PORT:-8090}"
PUBLIC_HOSTNAME="${PUBLIC_HOSTNAME:-cctv.zeaz.dev}"
TUNNEL_ID="${TUNNEL_ID:-c3d6aea4-15d5-4178-ba0c-b463cd908205}"

ENABLE_TURN_PORTS="false"
ENABLE_CLOUDFLARED_CONFIG="false"
INSTALL_RCLONE="false"
INSTALL_MQTT="false"

SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USER="${SMTP_USER:-}"
SMTP_FROM="${SMTP_FROM:-}"
EMAIL_TO="${EMAIL_TO:-}"

log(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
info(){ printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; }

usage(){
cat <<EOF
zEye v5 Pro Upgrade Prep

Usage:
  sudo bash zeye-v5-pro-upgrade.sh [options]

Options:
  --repo-dir <path>              Default: /home/zeazdev/zeye
  --opt-dir <path>               Default: /opt/zeye
  --port <port>                  Default: 9292
  --hostname <host>              Default: cctv.zeaz.dev
  --tunnel-id <uuid>             Cloudflare Tunnel UUID
  --enable-turn-ports            Publish UDP 3478 and 50000-50100
  --enable-cloudflared-config    Write enabled cloudflared/config.yml
  --install-rclone               Install rclone for backup workflow
  --install-mqtt                 Install mosquitto-clients for MQTT testing
  --smtp-host <host>             SMTP host placeholder
  --smtp-port <port>             SMTP port placeholder
  --smtp-user <user>             SMTP user placeholder
  --smtp-from <email>            SMTP sender placeholder
  --email-to <email>             Email recipient placeholder
  -h, --help                     Show help

Important:
  This prepares infrastructure only.
  Paid iSpyConnect/Agent DVR features still require a valid license/subscription.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --opt-dir) OPT_DIR="$2"; shift 2 ;;
    --port) WEB_PORT="$2"; shift 2 ;;
    --hostname) PUBLIC_HOSTNAME="$2"; shift 2 ;;
    --tunnel-id) TUNNEL_ID="$2"; shift 2 ;;
    --enable-turn-ports) ENABLE_TURN_PORTS="true"; shift ;;
    --enable-cloudflared-config) ENABLE_CLOUDFLARED_CONFIG="true"; shift ;;
    --install-rclone) INSTALL_RCLONE="true"; shift ;;
    --install-mqtt) INSTALL_MQTT="true"; shift ;;
    --smtp-host) SMTP_HOST="$2"; shift 2 ;;
    --smtp-port) SMTP_PORT="$2"; shift 2 ;;
    --smtp-user) SMTP_USER="$2"; shift 2 ;;
    --smtp-from) SMTP_FROM="$2"; shift 2 ;;
    --email-to) EMAIL_TO="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1"; usage; exit 1 ;;
  esac
done

[ "${EUID:-$(id -u)}" -eq 0 ] || { fail "Run with sudo"; exit 1; }

mkdir -p "$REPO_DIR"/{scripts,docs,cloudflared,home-assistant,rclone}
mkdir -p "$OPT_DIR"/{config,media,commands,cloud-backup,logs,ai,rtmp}
cd "$REPO_DIR"

info "Writing .env.pro.example"
cat > "$REPO_DIR/.env.pro.example" <<EOF
# zEye Pro licensed-feature readiness
# Do not commit real secrets.

PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
WEB_PORT=${WEB_PORT}
AGENTDVR_LOCAL_ORIGIN=http://127.0.0.1:${WEB_PORT}

SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASSWORD=
SMTP_FROM=${SMTP_FROM}
EMAIL_TO=${EMAIL_TO}

RCLONE_REMOTE=
RCLONE_RETENTION_DAYS=30

MQTT_HOST=homeassistant.local
MQTT_PORT=1883
MQTT_USER=
MQTT_PASSWORD=
MQTT_TOPIC_PREFIX=zeye/agentdvr

RTMP_URL=
AI_ENABLED=true
EOF

info "Writing Cloudflare templates"
cat > "$REPO_DIR/cloudflared/config.yml.example" <<EOF
# zEye Cloudflare Tunnel template
# Protect ${PUBLIC_HOSTNAME} with Cloudflare Access before public use.
# Do not commit credentials JSON or tunnel tokens.
#
# tunnel: ${TUNNEL_ID}
# credentials-file: /etc/cloudflared/${TUNNEL_ID}.json
#
# ingress:
#   - hostname: ${PUBLIC_HOSTNAME}
#     service: http://127.0.0.1:${WEB_PORT}
#   - service: http_status:404
EOF

if [ "$ENABLE_CLOUDFLARED_CONFIG" = "true" ]; then
  cat > "$REPO_DIR/cloudflared/config.yml" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${PUBLIC_HOSTNAME}
    service: http://127.0.0.1:${WEB_PORT}
  - service: http_status:404
EOF
  warn "Enabled cloudflared/config.yml written. Configure Cloudflare Access before public use."
fi

cat > "$REPO_DIR/docs/CLOUDFLARE_ACCESS.md" <<EOF
# Cloudflare Access for zEye

Recommended origin:

\`\`\`text
${PUBLIC_HOSTNAME} -> http://127.0.0.1:${WEB_PORT}
\`\`\`

Use Cloudflare Zero Trust Access with allowed users/groups, MFA/OTP, session duration, and audit logs.

Validate:

\`\`\`bash
sudo cloudflared tunnel ingress validate /etc/cloudflared/config.yml
sudo systemctl restart cloudflared
sudo systemctl status cloudflared --no-pager
\`\`\`
EOF

info "Writing cloud backup workflow"
cat > "$REPO_DIR/rclone/README.md" <<'EOF'
# zEye Cloud Upload Backup via rclone

This is server-side backup for recordings in `/opt/zeye/media`.
Agent DVR built-in cloud uploads may require an iSpyConnect license/subscription.

Setup:

```bash
rclone config
cp .env.pro.example .env.pro
nano .env.pro
bash scripts/cloud-backup.sh
```
EOF

cat > "$REPO_DIR/scripts/cloud-backup.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

if [ -f .env.pro ]; then
  set -a
  . ./.env.pro
  set +a
fi

RCLONE_REMOTE="${RCLONE_REMOTE:-}"
MEDIA_DIR="${MEDIA_DIR:-/opt/zeye/media}"
LOG_DIR="${LOG_DIR:-/opt/zeye/logs}"

mkdir -p "$LOG_DIR"

if [ -z "$RCLONE_REMOTE" ]; then
  echo "[FAIL] RCLONE_REMOTE is empty. Configure .env.pro first."
  exit 1
fi

if ! command -v rclone >/dev/null 2>&1; then
  echo "[FAIL] rclone not installed"
  exit 1
fi

rclone sync "$MEDIA_DIR" "$RCLONE_REMOTE" \
  --create-empty-src-dirs \
  --log-file "$LOG_DIR/rclone-zeye.log" \
  --log-level INFO

echo "[OK] Cloud backup complete"
EOF
chmod +x "$REPO_DIR/scripts/cloud-backup.sh"

info "Writing Home Assistant/MQTT helper"
cat > "$REPO_DIR/home-assistant/README.md" <<'EOF'
# zEye Home Assistant Integration

Recommended paths:
1. Use Agent DVR built-in integrations where available.
2. Use Agent DVR actions/webhooks to call Home Assistant webhook URLs.
3. Use MQTT where available.

Example webhook:

```text
http://homeassistant.local:8123/api/webhook/zeye-motion
```

MQTT topic convention:

```text
zeye/agentdvr/camera1/motion
zeye/agentdvr/camera1/status
```
EOF

cat > "$REPO_DIR/scripts/mqtt-test.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
[ -f .env.pro ] && set -a && . ./.env.pro && set +a

MQTT_HOST="${MQTT_HOST:-homeassistant.local}"
MQTT_PORT="${MQTT_PORT:-1883}"
MQTT_TOPIC_PREFIX="${MQTT_TOPIC_PREFIX:-zeye/agentdvr}"

mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" \
  -t "${MQTT_TOPIC_PREFIX}/test" \
  -m "{\"source\":\"zeye\",\"event\":\"test\",\"status\":\"ok\"}"
EOF
chmod +x "$REPO_DIR/scripts/mqtt-test.sh"

info "Writing Pro feature docs"
cat > "$REPO_DIR/docs/PRO_FEATURES_SETUP.md" <<'EOF'
# zEye Pro Features Setup

This repo prepares the infrastructure. Agent DVR/iSpyConnect premium services must be enabled with a valid license/subscription.

## Feature map

| Feature | zEye prep | Agent DVR/iSpyConnect step |
|---|---|---|
| Secured Remote Access | Cloudflare Access template | Sign in/apply license in Agent DVR |
| Rich Push Notifications | Mobile/app readiness notes | Enable in Agent DVR account/app |
| Email Notifications | SMTP checklist | Configure SMTP in Agent DVR UI |
| HD/4K Playback | Stable CPU baseline | License + adequate hardware/network |
| Cloud Uploads | rclone backup helper | Use licensed built-in cloud uploads if desired |
| Smart Home | HA/MQTT helper | Configure webhooks/MQTT/actions |
| User Permissions | Access docs | Configure Agent DVR users/roles |
| RTMP Streaming | RTMP placeholder | Configure licensed RTMP output |
| Software Updates | update script | Pull stable/beta image carefully |
| Virtual Reality Support | Docs only | Enable if supported/licensed |
| Built-in AI | AI readiness docs | Configure models in Agent DVR UI |

## Recommended camera UI

```text
Video Source:
  Source Type = Local Device
  Device      = /dev/video0

Advanced:
  Decoder     = CPU
  GPU Decoder = Default
  VLC Options = blank
```
EOF

cat > "$REPO_DIR/docs/EMAIL_NOTIFICATIONS.md" <<EOF
# Agent DVR Email Notifications

Configure actual SMTP values inside Agent DVR UI. Do not commit SMTP passwords.

\`\`\`text
SMTP Host: ${SMTP_HOST:-your.smtp.host}
SMTP Port: ${SMTP_PORT}
SMTP User: ${SMTP_USER:-your-user}
SMTP Password: <not committed>
From: ${SMTP_FROM:-camera@example.com}
To: ${EMAIL_TO:-receiver@example.com}
\`\`\`
EOF

cat > "$REPO_DIR/docs/USER_PERMISSIONS.md" <<'EOF'
# User Permissions

Use both layers:

1. Cloudflare Access
   - restrict who can reach cctv.zeaz.dev
   - MFA/OTP
   - audit logs

2. Agent DVR users
   - create separate users
   - avoid sharing admin account
   - assign camera-specific access where supported
EOF

cat > "$REPO_DIR/docs/AI_SETUP.md" <<'EOF'
# Built-in AI Readiness

Recommended:
- Confirm camera preview is stable first.
- Keep decoder CPU until stable.
- Enable AI/object detection from Agent DVR UI.
- Start with one camera and low frame sampling.
- Increase only after CPU/RAM is stable.

Check resources:

```bash
docker stats zeye-agentdvr
htop
```
EOF

cat > "$REPO_DIR/docs/RTMP_STREAMING.md" <<'EOF'
# RTMP Streaming Readiness

RTMP streaming may require a valid Agent DVR/iSpyConnect license.

Keep RTMP targets in `.env.pro` or in the Agent DVR UI only. Do not commit stream keys.
EOF

cat > "$REPO_DIR/scripts/update-agentdvr.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

mkdir -p /opt/zeye/backups
tar -czf "/opt/zeye/backups/zeye-config-$(date +%Y%m%d-%H%M%S).tgz" \
  docker-compose.yml .env* /opt/zeye/config 2>/dev/null || true

docker compose pull agentdvr
docker compose up -d
sleep 60
docker compose ps
bash scripts/health.sh
EOF
chmod +x "$REPO_DIR/scripts/update-agentdvr.sh"

info "Installing optional helper packages"
apt-get update
if [ "$INSTALL_RCLONE" = "true" ]; then
  apt-get install -y rclone
fi
if [ "$INSTALL_MQTT" = "true" ]; then
  apt-get install -y mosquitto-clients
fi

if [ "$ENABLE_TURN_PORTS" = "true" ] && [ -f "$REPO_DIR/docker-compose.yml" ]; then
  info "Enabling optional TURN UDP ports in docker-compose.yml"
  cp -a "$REPO_DIR/docker-compose.yml" "$REPO_DIR/docker-compose.yml.bak.pro.$(date +%Y%m%d-%H%M%S)"
  python3 - <<PY
from pathlib import Path
p = Path("$REPO_DIR/docker-compose.yml")
s = p.read_text()
if '"3478:3478/udp"' not in s:
    lines = s.splitlines()
    out = []
    inserted = False
    for line in lines:
        out.append(line)
        if line.strip() == f'- "{ "$WEB_PORT" }:{ "$CONTAINER_PORT" }"':
            out.append('      - "3478:3478/udp"')
            out.append('      - "50000-50100:50000-50100/udp"')
            inserted = True
    if not inserted:
        for i, line in enumerate(out):
            if line.strip() == "devices:":
                out.insert(i, '      - "50000-50100:50000-50100/udp"')
                out.insert(i, '      - "3478:3478/udp"')
                inserted = True
                break
    p.write_text("\\n".join(out) + "\\n")
PY
  cd "$REPO_DIR"
  docker compose config >/tmp/zeye-pro-compose-check.yml
  rm -f /tmp/zeye-pro-compose-check.yml
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -qi "Status: active"; then
  ufw allow "${WEB_PORT}/tcp" comment "zEye Agent DVR Web UI" || true
  if [ "$ENABLE_TURN_PORTS" = "true" ]; then
    ufw allow 3478/udp comment "zEye TURN" || true
    ufw allow 50000:50100/udp comment "zEye TURN relay" || true
  fi
fi

log "zEye v5 Pro upgrade prep complete"

cat <<EOF

Next manual steps:
1. Apply a valid iSpyConnect license/subscription in Agent DVR UI.
2. Configure iSpyConnect remote access/push notifications inside Agent DVR account settings.
3. Configure Cloudflare Access for ${PUBLIC_HOSTNAME}.
4. Configure SMTP in Agent DVR UI using docs/EMAIL_NOTIFICATIONS.md.
5. Configure rclone remote if using scripts/cloud-backup.sh.
6. Configure Home Assistant/MQTT using home-assistant/README.md.
7. Configure AI/RTMP/user permissions in Agent DVR UI.

Local URLs:
  http://127.0.0.1:${WEB_PORT}
  http://192.168.1.104:${WEB_PORT}
  http://192.168.1.100:${WEB_PORT}

EOF
