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
