#!/usr/bin/env bash
set -Eeuo pipefail

fail=0
say_fail(){ echo "[FAIL] $*"; fail=1; }

tracked_files(){
  git ls-files \
    ':!:tools/generators/**' \
    ':!:tools/bootstrap/legacy/**' \
    ':!:.repo-organize-backup/**' \
    ':!:zeye-repo-organizer/**' \
    ':!:zeye-endgame-starter/**' \
    ':!:zeye-endgame-final-fix/**' \
    ':!:.git/**'
}

echo "== zEye security check =="

echo
echo "1) Forbidden tracked runtime files"
for pattern in '(^|/)\.env$' 'cloudflared/.*\.(json|pem|cert)$' '(^|/).*\.(token|key|pem)$'; do
  hits="$(git ls-files | grep -E "$pattern" || true)"
  if [ -n "$hits" ]; then
    say_fail "Forbidden tracked file pattern: $pattern"
    echo "$hits"
  fi
done

echo
echo "2) Secret-like assignments"
tmp="$(mktemp /tmp/zeye-secret-scan.XXXXXX)"
turn_tmp="$(mktemp /tmp/zeye-turn-scan.XXXXXX)"
license_tmp="$(mktemp /tmp/zeye-license-scan.XXXXXX)"
trap 'rm -f "$tmp" "$turn_tmp" "$license_tmp"' EXIT

while IFS= read -r file; do
  [ -f "$file" ] || continue
  case "$file" in
    *.example|*.md|docs/*|AGENTS.md|scripts/security-check.sh) continue ;;
  esac

  grep -nE '([A-Z0-9_]*(PASSWORD|SECRET|TOKEN|API_KEY|LICENSE_KEY|STREAM_KEY|PRIVATE_KEY)[A-Z0-9_]*|RTMP_URL)=[^[:space:]]+' "$file" 2>/dev/null \
    | grep -viE '(placeholder|example|your_|redacted|changeme|todo|^#)' \
    | sed "s#^#${file}:#" >> "$tmp" || true

  grep -nE 'static-auth-secret[ =][A-Za-z0-9]{12,}' "$file" 2>/dev/null \
    | grep -viE '(redacted|placeholder|example)' \
    | sed "s#^#${file}:#" >> "$turn_tmp" || true
done < <(tracked_files)

if [ -s "$tmp" ]; then say_fail "Possible committed secret values"; cat "$tmp"; else echo "[OK] no suspicious non-placeholder assignments"; fi

echo
echo "3) TURN static-auth-secret leakage"
if [ -s "$turn_tmp" ]; then say_fail "Possible unredacted TURN static-auth-secret"; cat "$turn_tmp"; else echo "[OK] no unredacted TURN static-auth-secret"; fi

echo
echo "4) License compliance wording"
while IFS= read -r file; do
  [ -f "$file" ] || continue
  case "$file" in
    tools/generators/*|tools/bootstrap/legacy/*|scripts/security-check.sh) continue ;;
  esac

  grep -nEi '(crack|keygen|license[ -]?bypass|bypass.*license|spoof.*license|unlock paid|unlock.*paid|disable.*license|fake.*license)' "$file" 2>/dev/null \
    | grep -viE '(do not|does not|must not|never|without|no).*bypass|bypass.*(not allowed|prohibited)|license/subscription-gated|valid license|requires.*license|does not unlock|do not attempt' \
    | sed "s#^#${file}:#" >> "$license_tmp" || true
done < <(tracked_files)

if [ -s "$license_tmp" ]; then say_fail "Suspicious license-bypass wording"; cat "$license_tmp"; else echo "[OK] license compliance wording safe"; fi

echo
[ "$fail" -eq 0 ] && echo "[OK] security check passed"
exit "$fail"
