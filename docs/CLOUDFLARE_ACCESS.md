# Cloudflare Access Remote Access

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
