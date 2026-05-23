#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/../.."

echo "== zEye repo audit =="

echo
echo "== Important files =="
find . -maxdepth 3 -type f \
  -not -path './.git/*' \
  -not -path './.repo-organize-backup/*' \
  -not -path './zeye-repo-organizer/*' \
  -not -path './zeye-endgame-starter/*' \
  -not -path './zeye-endgame-final-fix/*' \
  | sort

echo
echo "== Bash syntax =="
for f in install-zeye.sh zeye-v4-installer.sh zeye-v5-pro-upgrade.sh scripts/*.sh tools/audit/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f" && echo "OK $f"
done

echo
echo "== Compose =="
docker compose config >/tmp/zeye-compose-audit.yml
rm -f /tmp/zeye-compose-audit.yml
echo "OK docker compose config"

echo
echo "== Git diff check =="
git diff --check
echo "OK git diff --check"

echo
echo "== Security =="
bash scripts/security-check.sh

echo
echo "== Git status =="
git status --short

echo
echo "[OK] repo audit complete"
