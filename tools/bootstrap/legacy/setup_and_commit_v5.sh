#!/bin/bash
set -e

echo "Running python generator v5..."
python3 /home/zeazdev/zeye/generate_zeye_v5.py

echo "Making scripts executable..."
chmod +x /home/zeazdev/zeye/scripts/mqtt-test.sh

cd /home/zeazdev/zeye

echo "Validating syntax..."
bash -n scripts/mqtt-test.sh

echo "Git status before..."
git diff --check || true

echo "Committing specified paths..."
git config user.email "antigravity@gemini.com" || true
git config user.name "Antigravity" || true

git add docs/EMAIL_NOTIFICATIONS.md docs/SMART_HOME.md home-assistant scripts/mqtt-test.sh
git commit -m "feat: add notification and smart home readiness"
git push origin main || echo "Git push failed, check remote configuration."

echo "Done."
