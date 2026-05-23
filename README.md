# zEye Agent DVR USB Webcam CCTV Stack

Welcome to the zEye Agent DVR CCTV stack for Ubuntu + Docker. This repository provides a secure, production-grade infrastructure deployment for Agent DVR, specifically optimized for USB webcams on local servers.

## Features

- **Docker-based Deployment**: Uses `mekayelanik/ispyagentdvr:latest`.
- **Secure by Default**: No public ports exposed directly. Internal port 8090 mapped to 9292 on host.
- **Hardware Passthrough**: Ready for `/dev/video*` USB camera passthrough with root-camera mode.
- **Agent DVR Pro Readiness**: Templates and guides for activating and configuring Pro features (requires active license).
- **Cloudflare Access Ready**: Templates for securely exposing your instance via Cloudflare Tunnels (e.g., `cctv.zeaz.dev`).

## Security

This stack is designed so that your CCTV system is **not** exposed directly to the public internet. See docs/SECURITY.md for more details.

> **Note**: Do NOT commit any `.env` files or Cloudflare credentials to this repository.
