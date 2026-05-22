#!/usr/bin/env bash
set -Eeuo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release v4l-utils wget

if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get install -y docker.io docker-compose-plugin
fi

sudo systemctl enable --now docker

if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

ZEYE_DATA_DIR="${ZEYE_DATA_DIR:-/opt/zeye/agentdvr}"
sudo install -d -m 0750 "$ZEYE_DATA_DIR/config" "$ZEYE_DATA_DIR/media" "$ZEYE_DATA_DIR/commands"
sudo chown -R "${PUID:-1000}:${PGID:-1000}" "$ZEYE_DATA_DIR"

if groups "$USER" | grep -qw docker; then
  echo "[OK] user already in docker group"
else
  sudo usermod -aG docker "$USER" || true
  echo "[WARN] Added $USER to docker group. Log out/in if docker permission fails."
fi

echo "[OK] Docker ready"
