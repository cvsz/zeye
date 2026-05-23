#!/bin/bash
set -e

echo "Running python generator v2..."
python3 /home/zeazdev/zeye/generate_zeye_v2.py

echo "Making scripts executable..."
find /home/zeazdev/zeye -name "*.sh" -exec chmod +x {} +

cd /home/zeazdev/zeye

echo "Validating syntax..."
bash -n install-zeye.sh
bash -n zeye-v4-installer.sh
find scripts -name "*.sh" -print0 | xargs -0 -n1 bash -n

echo "Validating docker compose..."
docker compose config > /dev/null

echo "Git status..."
git diff --check || true
git status --short

echo "Committing..."
git config user.email "antigravity@gemini.com" || true
git config user.name "Antigravity" || true
git add .
git commit -m "fix: harden installer and docker compose generation"
git push origin main || echo "Git push failed, check remote configuration."
