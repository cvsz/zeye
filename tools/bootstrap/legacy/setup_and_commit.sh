#!/bin/bash
set -e

echo "Running python generator..."
python3 /home/zeazdev/zeye/generate_zeye.py

echo "Making scripts executable..."
find /home/zeazdev/zeye -name "*.sh" -exec chmod +x {} +

cd /home/zeazdev/zeye

echo "Validating syntax..."
bash -n install-zeye.sh
bash -n zeye-v4-installer.sh
bash -n zeye-v5-pro-upgrade.sh
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
git commit -m "feat: initialize zEye Agent DVR CCTV stack"
git push origin main || echo "Git push failed, check remote configuration."

echo "Done. Final URLs:"
echo "http://127.0.0.1:9292"
echo "http://192.168.1.104:9292"
echo "http://192.168.1.100:9292"
