#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

echo "== zEye Full Starter =="

echo
echo "1) Compose validation"
docker compose config >/tmp/zeye-full-starter-compose.yml
rm -f /tmp/zeye-full-starter-compose.yml
echo "OK: docker compose config"

echo
echo "2) Camera permissions"
if [ -x scripts/camera-permissions.sh ]; then
  bash scripts/camera-permissions.sh
else
  sudo chmod 666 /dev/video* 2>/dev/null || true
fi

echo
echo "3) Start stack"
docker compose up -d
sleep 45

echo
echo "4) Health"
bash scripts/health.sh

echo
echo "5) Final URLs"
echo "Local: http://127.0.0.1:9292"
for ip in $(hostname -I 2>/dev/null || true); do
  case "$ip" in
    172.*|127.*|*:* ) continue ;;
    *) echo "LAN  : http://${ip}:9292" ;;
  esac
done

echo
echo "6) Agent DVR UI"
cat <<'SETTINGS'
Video Source:
  Source Type = Local Device
  Device      = /dev/video0

Advanced:
  Decoder     = CPU
  GPU Decoder = Default
  VLC Options = blank
SETTINGS

echo
echo "OK: zEye starter completed"
