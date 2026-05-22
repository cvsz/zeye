# zEye v4

Agent DVR USB webcam CCTV stack for Ubuntu + Docker.

## Known-good defaults

- Host UI: `http://<server-ip>:9292`
- Container UI: `8090`
- Mapping: `9292:8090`
- Primary camera: `/dev/video0`
- Decoder: CPU
- Cloudflare origin: `http://127.0.0.1:9292`

## Install / Repair

```bash
sudo bash zeye-v4-installer.sh --repo-dir /home/zeazdev/zeye --opt-dir /opt/zeye --port 9292 --mode root-camera
```

## Agent DVR UI

```text
Video Source:
  Source Type = Local Device
  Device      = /dev/video0

Advanced:
  Decoder     = CPU
  GPU Decoder = Default
  VLC Options = blank
```
# zeye
# zeye
