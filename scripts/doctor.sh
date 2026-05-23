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
