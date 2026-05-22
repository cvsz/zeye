#!/usr/bin/env bash
set -Eeuo pipefail

if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

DEVICE="${USB_VIDEO_DEVICE:-/dev/video0}"

echo "== USB video devices =="
ls -l /dev/video* 2>/dev/null || {
  echo "[FAIL] No /dev/video* devices found. Check USB camera connection."
  exit 1
}

echo
if command -v v4l2-ctl >/dev/null 2>&1; then
  v4l2-ctl --list-devices || true
  echo
  if [ -e "$DEVICE" ]; then
    v4l2-ctl -d "$DEVICE" --all || true
  fi
else
  echo "[WARN] v4l2-ctl not installed. Run scripts/install-docker.sh first."
fi

if [ -e "$DEVICE" ]; then
  echo "[OK] USB camera device exists: $DEVICE"
else
  echo "[FAIL] Expected USB camera device missing: $DEVICE"
  exit 1
fi
