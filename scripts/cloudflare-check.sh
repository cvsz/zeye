#!/bin/bash
set -e

echo "Checking cloudflared installation..."
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared is NOT installed."
else
    echo "cloudflared is installed: $(cloudflared --version)"
fi

echo "Checking /etc/cloudflared/config.yml..."
if [ -f /etc/cloudflared/config.yml ]; then
    echo "Validating config..."
    cloudflared tunnel ingress validate || echo "Config validation warning/error."
else
    echo "/etc/cloudflared/config.yml not found."
fi

echo "Checking cloudflared service status..."
systemctl is-active cloudflared >/dev/null 2>&1 && echo "cloudflared service is ACTIVE." || echo "cloudflared service is NOT active."

echo "Testing local origin HTTP (127.0.0.1:9292)..."
curl -m 2 -s -o /dev/null -w "Origin HTTP Status: %{http_code}\n" http://127.0.0.1:9292 || echo "Origin unreachable."

echo ""
echo "=== RECOMMENDED ACCESS POLICY CHECKLIST ==="
echo " [ ] cctv.zeaz.dev is proxied via Cloudflare."
echo " [ ] An Access Application is created for cctv.zeaz.dev."
echo " [ ] Access Policy requires secure authentication (e.g., Email OTP, SAML, OIDC)."
echo " [ ] Bypass rules are strictly limited and documented."
echo " [ ] Tunnel credentials and tokens are excluded from version control."
echo "==========================================="
