#!/bin/bash
set -e

cd /home/zeazdev/zeye

echo "Validating syntax..."
bash -n install-zeye.sh
bash -n zeye-v4-installer.sh
bash -n zeye-v5-pro-upgrade.sh
find scripts -name "*.sh" -print0 | xargs -0 -n1 bash -n

echo "Validating docker compose..."
docker compose config >/dev/null

echo "Git diff check..."
git diff --check || true

if [ -n "$(git status --porcelain)" ]; then
    echo "Committing fixes..."
    git config user.email "antigravity@gemini.com" || true
    git config user.name "Antigravity" || true
    git add .
    git commit -m "chore: finalize zEye full feature implementation"
    git push origin main || echo "Git push failed."
fi

echo "Done."
