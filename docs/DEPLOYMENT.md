# Deployment Guide

## Architecture

This stack is deployed using Docker via `docker-compose.yml`.
- **Internal Port**: The Agent DVR internal web UI port is `8090`.
- **Host Port**: The proxy port mapped to the host is `9292` (`9292:8090`).
- **Cloudflare Origin**: When using Cloudflare Tunnels, point your ingress rule to `http://127.0.0.1:9292`.

## Current Stable Mode: Root-Camera Mode

The `docker-compose.yml` is configured by default for **root-camera mode**, which is the current stable mode for reliable USB camera passthrough on Ubuntu. It uses `PUID=0`, `PGID=0`, `privileged: true`, and device cgroup rules (`c 81:* rmw`) to ensure the container has uninterrupted access to the video devices.

## USB Camera Devices

When connecting USB cameras, the system generates multiple `/dev/video*` devices. Their roles are as follows:
- `/dev/video0`: **Primary** capture endpoint (supports MJPEG/YUYV up to 1280x720).
- `/dev/video2`: **Fallback** capture endpoint (supports YUYV/MJPEG formats).
- `/dev/video1` and `/dev/video3`: **Non-capture / Metadata** endpoints. Do not use these in the Agent DVR UI for video sourcing.

## Agent DVR UI Settings

For the most stable stream using `/dev/video0`:
- **Video Source**: Local Device
- **Device**: /dev/video0
- **Decoder**: CPU (Leave GPU Decoder as Default)
- **VLC Options**: (blank)

## Security

Always protect your CCTV with a Cloudflare Access Zero Trust policy if you plan to access it remotely. Never expose `cctv.zeaz.dev` publicly without an Access warning/protection.