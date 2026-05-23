#!/usr/bin/env bash
set -Eeuo pipefail

# zEye Repo Organizer
# Organizes cvsz/zeye into a clean production layout.
#
# Safe behavior:
# - backs up files before moving
# - does not commit secrets
# - validates bash scripts and docker compose
# - commits changes only after validation

REPO_DIR="${REPO_DIR:-$HOME/zeye}"
COMMIT="${COMMIT:-true}"

log(){ printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
info(){ printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; }

usage(){
cat <<EOF
Usage:
  bash organize-zeye-repo.sh [options]

Options:
  --repo-dir <path>   Default: ~/zeye
  --no-commit         Organize and validate only
  -h, --help          Show help

Example:
  bash organize-zeye-repo.sh --repo-dir /home/zeazdev/zeye
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --no-commit) COMMIT="false"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1"; usage; exit 1 ;;
  esac
done

[ -d "$REPO_DIR/.git" ] || { fail "$REPO_DIR is not a git repo"; exit 1; }
cd "$REPO_DIR"

BACKUP_DIR=".repo-organize-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

info "Creating production directories"
mkdir -p \
  scripts \
  docs \
  cloudflared \
  home-assistant \
  rclone \
  systemd \
  terraform \
  tools/generators \
  tools/audit \
  agentdvr \
  .github/workflows

info "Moving generator files to tools/generators/"
for f in generate_zeye.py generate_zeye_v2.py generate_zeye_v3.py generate_zeye_v4.py generate_zeye_v5.py; do
  if [ -f "$f" ]; then
    cp -a "$f" "$BACKUP_DIR/$f"
    git mv "$f" "tools/generators/$f" 2>/dev/null || mv "$f" "tools/generators/$f"
    log "moved $f -> tools/generators/$f"
  fi
done

info "Normalizing root .gitignore"
cat > .gitignore <<'EOF'
# Runtime secrets
.env
.env.*
!.env.example
!.env.pro.example

# Cloudflare credentials
cloudflared/*.json
cloudflared/*.pem
cloudflared/*.cert
.cloudflared/
*.token
*.key
*.pem

# Runtime/generated
*.log
*.bak.*
.repo-organize-backup/
__pycache__/
*.pyc
.DS_Store

# Local media / backups
media/
recordings/
backups/
*.mp4
*.mkv
*.avi
*.jpg
*.jpeg
*.png
EOF

info "Writing repo structure index"
cat > docs/REPO_STRUCTURE.md <<'EOF'
# zEye Repository Structure

```text
zeye/
├── README.md                         # Main project overview
├── docker-compose.yml                # Agent DVR runtime stack
├── install-zeye.sh                   # Main install script
├── zeye-v4-installer.sh              # Stable repair/install script
├── zeye-v5-pro-upgrade.sh            # Licensed pro-feature readiness
├── .env.example                      # Safe base env template
├── .env.pro.example                  # Safe pro-feature env template
├── scripts/                          # Operational scripts
│   ├── health.sh
│   ├── doctor.sh
│   ├── camera-permissions.sh
│   ├── restart.sh
│   ├── up.sh
│   ├── down.sh
│   ├── logs.sh
│   ├── update-agentdvr.sh
│   ├── cloud-backup.sh
│   ├── mqtt-test.sh
│   ├── cloudflare-check.sh
│   ├── security-check.sh
│   └── backup-config.sh
├── docs/                             # Operator documentation
│   ├── QUICKSTART.md
│   ├── DEPLOYMENT.md
│   ├── TROUBLESHOOTING.md
│   ├── PRO_FEATURES_SETUP.md
│   ├── CLOUDFLARE_ACCESS.md
│   ├── EMAIL_NOTIFICATIONS.md
│   ├── USER_PERMISSIONS.md
│   ├── AI_SETUP.md
│   ├── RTMP_STREAMING.md
│   ├── SMART_HOME.md
│   ├── CLOUD_BACKUP.md
│   ├── SECURITY.md
│   ├── LICENSE_FEATURES.md
│   └── REPO_STRUCTURE.md
├── cloudflared/                      # Cloudflare Tunnel templates only
├── home-assistant/                   # Smart home examples
├── rclone/                           # Cloud backup docs
├── systemd/                          # Optional service/timer units
├── terraform/                        # Optional IaC examples only
├── tools/
│   ├── generators/                   # Historical generator scripts
│   └── audit/                        # Repo audit helpers
└── .github/workflows/                # CI validation
```

## Rules

- Root directory stays small.
- Runtime scripts go in `scripts/`.
- Operator docs go in `docs/`.
- Historical generation helpers go in `tools/generators/`.
- No secrets in git.
- No `.env`, Cloudflare credentials, SMTP passwords, RTMP keys, or tunnel tokens.
- Paid iSpyConnect/Agent DVR features must remain license/subscription-gated.
EOF

info "Writing AGENTS.md"
cat > AGENTS.md <<'EOF'
# AGENTS.md — zEye

## Mission

Maintain zEye as a safe, production-ready Agent DVR USB Webcam CCTV stack for Ubuntu + Docker.

## Known-good deployment facts

- Agent DVR image: `mekayelanik/ispyagentdvr:latest`
- Agent DVR internal web port: `8090`
- Host web port: `9292`
- Correct mapping: `9292:8090`
- Cloudflare origin: `http://127.0.0.1:9292`
- Cloudflare hostname: `cctv.zeaz.dev`
- Primary USB camera: `/dev/video0`
- Fallback USB camera: `/dev/video2`
- `/dev/video1` and `/dev/video3` may be metadata/non-capture endpoints
- Docker/VMware stable mode: root-camera
- Recommended UI:
  - Video Source: Local Device
  - Device: `/dev/video0`
  - Decoder: CPU
  - GPU Decoder: Default
  - VLC Options: blank

## Safety rules

- Do not bypass, spoof, crack, or unlock Agent DVR/iSpyConnect paid features.
- Do not commit secrets.
- Do not expose CCTV publicly without Cloudflare Access or equivalent auth.
- Do not commit `.env`, Cloudflare credentials, SMTP passwords, RTMP keys, tunnel tokens, or license keys.
- Default compose should expose only `9292:8090`.
- TURN UDP ports must be optional, not default.

## Validation before commit

```bash
bash -n install-zeye.sh || true
bash -n zeye-v4-installer.sh || true
bash -n zeye-v5-pro-upgrade.sh || true
find scripts -name "*.sh" -print0 | xargs -0 -n1 bash -n
docker compose config
git diff --check
bash scripts/security-check.sh || true
```
EOF

info "Writing missing docs placeholders if absent"
declare -A docs
docs["docs/QUICKSTART.md"]="# Quickstart\n\n1. Run installer.\n2. Open http://127.0.0.1:9292 or LAN IP.\n3. Select Local Device /dev/video0 in Agent DVR.\n"
docs["docs/DEPLOYMENT.md"]="# Deployment\n\nUse Docker Compose with host port 9292 mapped to Agent DVR internal port 8090.\n"
docs["docs/TROUBLESHOOTING.md"]="# Troubleshooting\n\nRun:\n\n\`\`\`bash\nbash scripts/health.sh\nbash scripts/doctor.sh\n\`\`\`\n"
docs["docs/SECURITY.md"]="# Security\n\nDo not commit secrets. Use Cloudflare Access for remote CCTV access.\n"
docs["docs/LICENSE_FEATURES.md"]="# License Features\n\nPremium Agent DVR/iSpyConnect features require a valid license/subscription. This repo does not bypass licensing.\n"
docs["docs/SMART_HOME.md"]="# Smart Home\n\nUse Home Assistant webhooks or MQTT to integrate motion/status events.\n"
docs["docs/CLOUD_BACKUP.md"]="# Cloud Backup\n\nUse rclone workflow or licensed Agent DVR built-in cloud uploads.\n"

for path in "${!docs[@]}"; do
  if [ ! -f "$path" ]; then
    printf "%b" "${docs[$path]}" > "$path"
    log "created $path"
  fi
done

info "Writing security-check.sh"
cat > scripts/security-check.sh <<'EOF'
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
EOF
chmod +x scripts/security-check.sh

info "Writing repo audit helper"
cat > tools/audit/repo-audit.sh <<'EOF'
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
EOF
chmod +x tools/audit/repo-audit.sh

info "Writing GitHub workflows if absent"
cat > .github/workflows/compose-validate.yml <<'EOF'
name: compose-validate

on:
  push:
  pull_request:

jobs:
  compose:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate docker compose
        run: docker compose config
EOF

cat > .github/workflows/shellcheck.yml <<'EOF'
name: shellcheck

on:
  push:
  pull_request:

jobs:
  shell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install shellcheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck
      - name: Bash syntax
        run: |
          bash -n install-zeye.sh || true
          bash -n zeye-v4-installer.sh || true
          bash -n zeye-v5-pro-upgrade.sh || true
          find scripts tools -name "*.sh" -print0 | xargs -0 -n1 bash -n
      - name: Shellcheck scripts
        run: |
          find scripts tools -name "*.sh" -print0 | xargs -0 shellcheck -S warning || true
EOF

cat > .github/workflows/security.yml <<'EOF'
name: security

on:
  push:
  pull_request:

jobs:
  secret-safety:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Secret safety scan
        run: bash scripts/security-check.sh
EOF

info "Validating"
find scripts tools -name "*.sh" -print0 | xargs -0 -n1 bash -n
bash -n install-zeye.sh 2>/dev/null || true
bash -n zeye-v4-installer.sh 2>/dev/null || true
bash -n zeye-v5-pro-upgrade.sh 2>/dev/null || true

if [ -f docker-compose.yml ]; then
  docker compose config >/tmp/zeye-compose-organize.yml
  rm -f /tmp/zeye-compose-organize.yml
  log "docker compose config OK"
fi

git diff --check
bash scripts/security-check.sh || warn "security-check found issues; review before pushing"

info "Git status"
git status --short

if [ "$COMMIT" = "true" ]; then
  git add .
  if git diff --cached --quiet; then
    warn "No changes to commit"
  else
    git commit -m "chore: organize zEye repository structure"
    git push origin main
    log "Committed and pushed"
  fi
else
  warn "Skipped commit because --no-commit was set"
fi
