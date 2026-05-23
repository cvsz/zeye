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
