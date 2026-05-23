#!/usr/bin/env bash
set -Eeuo pipefail

echo "== USB camera check =="
if ls /dev/video* >/dev/null 2>&1; then
  ls -l /dev/video*
else
  echo "[FAIL] No /dev/video* devices found."
  echo "For VMware: VM -> Removable Devices -> USB Camera -> Connect to this VM"
  exit 1
fi

echo
echo "== lsusb =="
lsusb || true

echo
echo "== v4l2 devices =="
if command -v v4l2-ctl >/dev/null 2>&1; then
  v4l2-ctl --list-devices || true
  for d in /dev/video*; do
    echo
    echo "== $d formats =="
    v4l2-ctl --device="$d" --list-formats-ext || true
  done
else
  echo "Install v4l-utils: sudo apt-get install -y v4l-utils"
fi
