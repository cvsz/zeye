# zEye v5 Pro Upgrade

Prepares zEye for licensed Agent DVR/iSpyConnect premium workflows.

This does not bypass licensing. Use a valid iSpyConnect subscription/license for remote access, push notifications, cloud uploads, RTMP, HD/4K playback, business use, and other licensed services.

## Run

```bash
sudo bash zeye-v5-pro-upgrade.sh \
  --repo-dir /home/zeazdev/zeye \
  --opt-dir /opt/zeye \
  --port 9292 \
  --hostname cctv.zeaz.dev \
  --tunnel-id c3d6aea4-15d5-4178-ba0c-b463cd908205 \
  --install-rclone \
  --install-mqtt
```

## Optional TURN/WebRTC ports

```bash
sudo bash zeye-v5-pro-upgrade.sh --enable-turn-ports
```

Default is safer and does not publish TURN UDP ports.
