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
