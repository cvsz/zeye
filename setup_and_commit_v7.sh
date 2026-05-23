#!/bin/bash
set -e

echo "Running python generator v7..."
python3 /home/zeazdev/zeye/generate_zeye_v7.py

cd /home/zeazdev/zeye

echo "Git status before..."
git diff --check || true

echo "Committing specified paths..."
git config user.email "antigravity@gemini.com" || true
git config user.name "Antigravity" || true

git add .github docs/SECURITY.md
git commit -m "ci: add validation and secret safety checks"
git push origin main || echo "Git push failed, check remote configuration."

echo "Done."
