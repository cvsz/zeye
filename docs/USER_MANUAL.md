# zEye User Manual

This manual is a zEye-specific operator guide for Agent DVR running in Docker on Ubuntu. It summarizes the official Agent DVR user guide and adapts it to the known zEye deployment.

Official reference: https://www.ispyconnect.com/docs/agent/about

## 1. zEye access URLs

Default local and LAN URLs:

```text
Local: http://127.0.0.1:9292
LAN  : http://192.168.1.104:9292
LAN  : http://192.168.1.100:9292
```

Agent DVR normally uses internal port `8090`. In zEye Docker, the host publishes:

```text
9292 -> 8090
```

Cloudflare Tunnel origin, when enabled:

```text
cctv.zeaz.dev -> http://127.0.0.1:9292
```

Use Cloudflare Access or another authentication layer before exposing CCTV remotely.

## 2. First login and main UI

After opening zEye in a browser:

1. Use the top-left alerts/armed control to enable or disable the main alert state.
2. Use the top-center main menu to switch views or fullscreen.
3. Use the top-right server/account menus for server settings, account settings, and alert lists.
4. Use the bottom controls/edit-view area to add devices and arrange camera slots.

## 3. Add USB webcam as CCTV camera

Recommended zEye USB camera settings:

```text
Video Source:
  Source Type = Local Device
  Device      = /dev/video0

Advanced:
  Decoder     = CPU
  GPU Decoder = Default
  VLC Options = blank
```

Known device notes:

```text
/dev/video0 = primary camera, MJPEG/YUYV formats, best first choice
/dev/video2 = fallback camera, YUYV/MJPEG formats
/dev/video1 = may be metadata/non-capture endpoint
/dev/video3 = may be metadata/non-capture endpoint
```

If the camera does not appear:

```bash
cd ~/zeye
bash scripts/camera-permissions.sh
bash scripts/restart.sh
bash scripts/doctor.sh
```

## 4. Network and firewall

For zEye Docker, open the web UI port:

```bash
sudo ufw allow 9292/tcp comment "zEye Agent DVR Web UI"
sudo ufw reload
sudo ufw status verbose
```

Optional WebRTC/TURN ports are not enabled by default. Enable them only when needed:

```text
3478/udp
50000-50100/udp
```

Use:

```bash
sudo bash zeye-v4-installer.sh --enable-turn-ports
```

Do not expose TURN/public CCTV ports without access control.

## 5. Daily operations

Health check:

```bash
cd ~/zeye
bash scripts/health.sh
```

Deep diagnostics:

```bash
bash scripts/doctor.sh
```

Restart:

```bash
bash scripts/restart.sh
```

Follow logs with secrets redacted:

```bash
bash scripts/logs.sh
```

Update Agent DVR Docker image with backup:

```bash
bash scripts/update-agentdvr.sh
```

## 6. Recordings and storage

zEye stores Agent DVR media under:

```text
/opt/zeye/media
```

Config is stored under:

```text
/opt/zeye/config
```

Back up before upgrades:

```bash
cd ~/zeye
bash scripts/backup-config.sh
```

For cloud backup readiness, configure `rclone` and `.env.pro`, then run:

```bash
bash scripts/cloud-backup.sh
```

## 7. Performance baseline

Recommended starting point for VMware/Docker:

```text
Decoder = CPU
GPU Decoder = Default
One camera first
/dev/video0 first
Lower FPS/resolution if CPU is high
Disable audio if not needed
```

Check resource usage:

```bash
docker stats zeye-agentdvr
free -h
df -h /opt/zeye
```

## 8. Remote access

Recommended secure remote options:

1. Cloudflare Access + Cloudflare Tunnel to `http://127.0.0.1:9292`.
2. Cloudflare WARP/private route for administrator access.
3. iSpyConnect remote access if you have a valid license/subscription.

Do not publish the UI directly to the internet without authentication.

## 9. Notifications and Pro features

The following features may require a valid Agent DVR/iSpyConnect license or hosted service:

- iSpyConnect secured remote access
- Rich mobile push notifications
- Higher resolution playback / 4K workflows
- Built-in cloud upload services
- RTMP streaming
- Expanded users/permissions
- Some mobile/app/hosted services

zEye provides infrastructure readiness only. It does not bypass licensing.

## 10. Smart home integration

Use one of these paths:

- Agent DVR actions/webhooks to Home Assistant webhooks.
- MQTT topics such as `zeye/agentdvr/camera1/motion`.
- Alexa/IFTTT through Home Assistant or supported Agent DVR integrations.

Example test:

```bash
bash scripts/mqtt-test.sh
```

## 11. AI readiness

Recommended first AI setup:

1. Confirm camera preview is stable.
2. Keep decoder on CPU.
3. Enable AI/object detection from Agent DVR UI.
4. Start with one camera and low sampling.
5. Increase processing only after CPU/RAM is stable.

## 12. Troubleshooting quick map

| Symptom | Command | Likely fix |
|---|---|---|
| Web UI not reachable | `bash scripts/health.sh` | Check port 9292 and compose status |
| Camera missing | `bash scripts/doctor.sh` | Run camera permissions and restart |
| Compose YAML error | `docker compose config` | Re-run `zeye-v4-installer.sh` |
| Remote browser error | `bash scripts/cloudflare-check.sh` | Validate Cloudflare Access/Tunnel |
| High CPU | `docker stats zeye-agentdvr` | Reduce FPS/resolution, CPU decoder first |

## 13. Official docs index

Primary official manual:

```text
https://www.ispyconnect.com/docs/agent/about
```

Useful official manual sections to review from the Agent DVR guide:

- About Agent DVR
- First Steps
- Performance Tips
- Installing
- LAN / network access
- Updating Agent DVR
- Adding Cameras
- Video Sources / Local Device
- Server Settings
- Notifications
- Permissions
- RTMP Streaming
- Storage Management
- MQTT
- Virtual Reality
