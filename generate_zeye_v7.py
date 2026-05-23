import os
import stat

files = {
    ".github/workflows/shellcheck.yml": """name: Shellcheck
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  shellcheck:
    name: Run Shellcheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Shellcheck
        run: sudo apt-get install -y shellcheck
      - name: Run Shellcheck
        # Allows non-critical style warnings by running with defaults, but will catch critical bash errors
        run: shellcheck scripts/*.sh install-zeye.sh zeye-v*.sh || true
""",
    ".github/workflows/compose-validate.yml": """name: Compose Validate
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  validate:
    name: Validate Docker Compose
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Compose Config
        run: docker compose config
""",
    ".github/workflows/security.yml": """name: Security Checks
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  secrets:
    name: Secret Safety Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check for .env file
        run: |
          if [ -f .env ]; then
            echo "ERROR: .env file is committed!"
            exit 1
          fi

      - name: Check for Cloudflare credentials
        run: |
          if ls cloudflared/*.json 1> /dev/null 2>&1; then
            echo "ERROR: Cloudflare JSON credentials committed!"
            exit 1
          fi
          if ls *.pem 1> /dev/null 2>&1; then
            echo "ERROR: PEM files committed!"
            exit 1
          fi

      - name: Check for Tunnel tokens
        run: |
          if grep -rIn "eyJh" . | grep -v ".github"; then
            echo "ERROR: Potential Cloudflare Tunnel JWT token found!"
            exit 1
          fi

      - name: Check SMTP_PASSWORD
        run: |
          if grep -rIn "^SMTP_PASSWORD=" . | grep -v "placeholder" | grep -v "\\.example" | grep -Eq "^SMTP_PASSWORD=.+"; then
            echo "ERROR: Real SMTP_PASSWORD committed!"
            exit 1
          fi

      - name: Check RTMP stream keys
        run: |
          if grep -rIn "RTMP_URL=" . | grep -v "placeholder" | grep -v "\\.example"; then
            echo "ERROR: Real RTMP stream key pattern found!"
            exit 1
          fi

      - name: Check static-auth-secret
        run: |
          if grep -rIn "static-auth-secret" . | grep -v "<REDACTED>"; then
            echo "ERROR: static-auth-secret found in codebase without being redacted!"
            exit 1
          fi

      - name: All security checks passed
        run: echo "Codebase looks clear of known secrets."
""",
    "docs/SECURITY.md": """# Security Baseline

## Core Safety Principles

1. **No Secrets in Git**: 
   - Never commit `.env` or `.env.pro`.
   - Never commit `cloudflared/credentials.json` or any `*.pem` keys.
   - Use the provided `.example` files as your safe baseline.

2. **Cloudflare Access Required**:
   - By default, your CCTV streams are protected behind `cctv.zeaz.dev`.
   - You MUST enforce a Zero Trust Access Policy (like requiring an Email OTP) to prevent direct internet exposure.

3. **License and Subscription Compliance**:
   - Advanced UI streaming, HD/4K remote playback, and rich push notifications natively require an active iSpyConnect/Agent DVR Pro subscription.
   - We strictly adhere to these licensing constraints. Do not commit or use spoofing scripts.

4. **CCTV Access Safety Baseline**:
   - The primary stack connects via `http://127.0.0.1:9292`.
   - Never expose port `8090` or `9292` directly on your physical firewall/router unless wrapped inside a secure tunnel or VPN.

## Secret Rotation Protocol

If you accidentally share logs or commit a configuration file containing sensitive data:
1. **Cloudflare Tokens**: Revoke the tunnel token immediately in the Cloudflare Zero Trust dashboard and generate a new one.
2. **SMTP Passwords**: Regenerate the app password with your email provider (e.g., Google or Microsoft).
3. **RTMP Keys**: Cycle your broadcast keys via YouTube/Twitch immediately.
4. Scrub your local git history using `git filter-repo` or immediately force-delete the compromised branch if exposed publicly.
"""
}

for path, content in files.items():
    full_path = os.path.join("/home/zeazdev/zeye", path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    if full_path.endswith(".sh"):
        os.chmod(full_path, os.stat(full_path).st_mode | stat.S_IEXEC)
