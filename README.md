# zEye — Agent DVR USB Camera Stack

`zEye` is a small Ubuntu/Docker deployment for Agent DVR using a local USB camera and a Cloudflare Tunnel-ready origin.

## Target

- App: Agent DVR
- USB camera: `/dev/video0`
- Local web UI: `http://127.0.0.1:9292`
- LAN web UI: `http://192.168.1.101:9292`
- Cloudflare hostname: `cctv.zeaz.dev`
- Tunnel origin service: `http://127.0.0.1:9292`

> Cloudflare Tunnel normally exposes the service as `https://cctv.zeaz.dev` and forwards to local port `9292`. Exposing `cctv.zeaz.dev:9292` publicly is not recommended unless you intentionally run DNS-only/direct networking or a paid product that supports arbitrary TCP/port proxying.

## Quick start on Ubuntu

```bash
cd zeye
cp .env.example .env
bash scripts/install-docker.sh
bash scripts/usb-camera-check.sh
bash scripts/up.sh
```

Open:

```text
http://192.168.1.101:9292
```

## Cloudflare Tunnel

Use `cloudflared/config.yml.example` as a template. Do not commit tunnel credentials or tokens.

Recommended public URL:

```text
https://cctv.zeaz.dev
```

Origin behind the tunnel:

```text
http://127.0.0.1:9292
```

## USB camera notes

Check camera device:

```bash
ls -l /dev/video*
v4l2-ctl --list-devices || true
```

If your USB camera is not `/dev/video0`, update `docker-compose.yml` and `.env`.

## Security defaults

- No real secrets committed.
- Agent DVR data stored under `/opt/zeye/agentdvr`.
- Cloudflare Tunnel config is an example only.
- Prefer Cloudflare Access/authentication before enabling public CCTV access.
