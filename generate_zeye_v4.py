import os
import stat

files = {
    "cloudflared/config.yml.example": """tunnel: c3d6aea4-15d5-4178-ba0c-b463cd908205
credentials-file: /etc/cloudflared/credentials.json
ingress:
  - hostname: cctv.zeaz.dev
    service: http://127.0.0.1:9292
  - service: http_status:404
""",
    "docs/CLOUDFLARE_ACCESS.md": """# Cloudflare Access Remote Access

## Overview

This guide explains how to safely expose your zEye Agent DVR installation (`http://127.0.0.1:9292`) using Cloudflare Tunnels and Cloudflare Access (Zero Trust). 

- **Cloudflare Tunnel HTTP**: This is excellent for accessing the Agent DVR web UI remotely without opening inbound ports on your router.
- **WebRTC/TURN UDP Limitations**: Be aware that WebRTC streaming and TURN UDP packets may not route effectively through a simple HTTP Cloudflare Tunnel.
- **WARP / Private Routes**: For reliable camera administrative access and UDP stream delivery, deploying Cloudflare WARP with a Private Network Route is highly preferred over a public-facing HTTP tunnel.
- **Direct Port Forwarding**: If direct TURN ports are strictly needed for specific mobile app functionality without WARP, use `./install-zeye.sh --enable-turn-ports` and configure your router/firewall rules with extreme caution.

## Configuration Steps

1. Review `cloudflared/config.yml.example`.
2. Configure your tunnel locally or via the Zero Trust dashboard.
3. Add an **Access Policy** requiring email authentication (e.g., OTP or SAML) to protect `cctv.zeaz.dev`.
4. Run `scripts/cloudflare-check.sh` to validate the tunnel configuration on your host.

> **CRITICAL**: Never expose CCTV without an Access policy. Do not commit your tunnel token or `credentials.json` to any repository.
""",
    "scripts/cloudflare-check.sh": """#!/bin/bash
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
curl -m 2 -s -o /dev/null -w "Origin HTTP Status: %{http_code}\\n" http://127.0.0.1:9292 || echo "Origin unreachable."

echo ""
echo "=== RECOMMENDED ACCESS POLICY CHECKLIST ==="
echo " [ ] cctv.zeaz.dev is proxied via Cloudflare."
echo " [ ] An Access Application is created for cctv.zeaz.dev."
echo " [ ] Access Policy requires secure authentication (e.g., Email OTP, SAML, OIDC)."
echo " [ ] Bypass rules are strictly limited and documented."
echo " [ ] Tunnel credentials and tokens are excluded from version control."
echo "==========================================="
""",
    "terraform/cloudflare-cctv-hostname.tf.example": """# Terraform configuration example for Cloudflare Tunnel and Access Policy
# Do not run `terraform apply` unless properly configured and secured.

resource "cloudflare_tunnel" "cctv_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "zeye-cctv-tunnel"
  secret     = var.tunnel_secret
}

resource "cloudflare_record" "cctv_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "cctv.zeaz.dev"
  value   = cloudflare_tunnel.cctv_tunnel.cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_access_application" "cctv_app" {
  zone_id          = var.cloudflare_zone_id
  name             = "zEye CCTV Access"
  domain           = "cctv.zeaz.dev"
  session_duration = "24h"
}

resource "cloudflare_access_policy" "cctv_policy" {
  application_id = cloudflare_access_application.cctv_app.id
  zone_id        = var.cloudflare_zone_id
  name           = "Require Email Auth"
  precedence     = "1"
  decision       = "allow"

  include {
    email = ["admin@zeaz.dev"]
  }
}
"""
}

for path, content in files.items():
    full_path = os.path.join("/home/zeazdev/zeye", path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    if full_path.endswith(".sh"):
        os.chmod(full_path, os.stat(full_path).st_mode | stat.S_IEXEC)
