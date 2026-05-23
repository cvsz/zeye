#!/bin/bash
set -e

echo "Running python generator v4..."
python3 /home/zeazdev/zeye/generate_zeye_v4.py

echo "Making scripts executable..."
chmod +x /home/zeazdev/zeye/scripts/cloudflare-check.sh

cd /home/zeazdev/zeye

echo "Validating scripts..."
bash -n scripts/cloudflare-check.sh

echo "Git status before..."
git diff --check || true

echo "Committing specified paths..."
git config user.email "antigravity@gemini.com" || true
git config user.name "Antigravity" || true

git add cloudflared docs/CLOUDFLARE_ACCESS.md scripts/cloudflare-check.sh terraform/
git commit -m "feat: add Cloudflare Access remote access templates"
git push origin main || echo "Git push failed, check remote configuration."

echo "Done."
