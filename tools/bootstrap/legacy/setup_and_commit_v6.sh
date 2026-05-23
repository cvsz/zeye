#!/bin/bash
set -e

echo "Running python generator v6..."
python3 /home/zeazdev/zeye/generate_zeye_v6.py

echo "Making scripts executable..."
chmod +x /home/zeazdev/zeye/scripts/resource-check.sh

cd /home/zeazdev/zeye

echo "Validating syntax..."
bash -n scripts/resource-check.sh

echo "Git status before..."
git diff --check || true

echo "Committing specified paths..."
git config user.email "antigravity@gemini.com" || true
git config user.name "Antigravity" || true

git add docs/AI_SETUP.md docs/RTMP_STREAMING.md docs/HD_4K_PLAYBACK.md scripts/resource-check.sh
git commit -m "docs: add AI RTMP and HD playback readiness"
git push origin main || echo "Git push failed, check remote configuration."

echo "Done."
