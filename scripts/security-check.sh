#!/usr/bin/env bash
set -Eeuo pipefail

fail=0

check_forbidden_file(){
  local pattern="$1"
  if git ls-files | grep -E "$pattern" >/dev/null 2>&1; then
    echo "[FAIL] Forbidden tracked file pattern: $pattern"
    git ls-files | grep -E "$pattern" || true
    fail=1
  fi
}

check_forbidden_file '(^|/)\.env$'
check_forbidden_file 'cloudflared/.*\.(json|pem|cert)$'
check_forbidden_file '(^|/).*\.(token|key|pem)$'

if git grep -nE '(SMTP_PASSWORD|RTMP_STREAM_KEY|TUNNEL_TOKEN|CF_TOKEN|API_KEY|LICENSE_KEY)=(.+[^[:space:]])' -- ':!*.example' ':!docs/*' >/tmp/zeye-secret-scan.txt 2>/dev/null; then
  echo "[FAIL] Possible committed secret values:"
  cat /tmp/zeye-secret-scan.txt
  fail=1
fi
rm -f /tmp/zeye-secret-scan.txt

if git grep -nE 'static-auth-secret [A-Za-z0-9]+' >/tmp/zeye-turn-secret.txt 2>/dev/null; then
  echo "[FAIL] TURN static-auth-secret appears unredacted:"
  cat /tmp/zeye-turn-secret.txt
  fail=1
fi
rm -f /tmp/zeye-turn-secret.txt

if [ "$fail" -eq 0 ]; then
  echo "[OK] security check passed"
fi

exit "$fail"
