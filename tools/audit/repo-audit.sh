#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/../.."

echo "== Files =="
find . -maxdepth 3 -type f | sort

echo
echo "== Bash syntax =="
for f in install-zeye.sh zeye-v4-installer.sh zeye-v5-pro-upgrade.sh scripts/*.sh tools/audit/*.sh; do
  [ -f "$f" ] || continue
  bash -n "$f" && echo "OK $f"
done

echo
echo "== Compose =="
docker compose config >/tmp/zeye-compose-audit.yml && echo "OK docker compose config"
rm -f /tmp/zeye-compose-audit.yml

echo
echo "== Git diff check =="
git diff --check

echo
echo "== Security =="
bash scripts/security-check.sh
