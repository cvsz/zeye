#!/usr/bin/env bash
set -Eeuo pipefail

REPO="cvsz/zeye"
BRANCH="main"

if ! command -v gh >/dev/null 2>&1; then
  echo "[FAIL] gh CLI is required: sudo apt-get install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "[FAIL] gh CLI not authenticated. Run: gh auth login"
  exit 1
fi

git init -b "$BRANCH"
git add .
git commit -m "init: add zEye Agent DVR USB camera stack"

gh repo create "$REPO" --public --source=. --remote=origin --push

echo "[OK] Created and pushed $REPO"
