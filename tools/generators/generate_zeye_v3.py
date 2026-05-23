import os
import stat

files = {
    "zeye-v5-pro-upgrade.sh": """#!/bin/bash
set -e
echo "Starting v5 Pro feature readiness setup..."

echo "Checking for .env.pro..."
if [ ! -f .env.pro ]; then
    echo "Copying .env.pro.example to .env.pro..."
    cp .env.pro.example .env.pro
fi

echo "Reminder: Pro features require a valid iSpyConnect subscription."
echo "Please edit .env.pro with your valid license details if applicable."
echo "Review docs/PRO_FEATURES_SETUP.md for full instructions."
echo "Done."
""",
    ".env.pro.example": """# Pro features require an active license from iSpyConnect
AGENTDVR_PRO_LICENSE=your_license_here
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=user@example.com
SMTP_PASSWORD=smtp_password_placeholder
RTMP_STREAM_KEY=rtmp_stream_key_placeholder
""",
    "docs/PRO_FEATURES_SETUP.md": """# Pro Features Setup

This infrastructure is prepared to support Agent DVR Pro features.
**Note**: You must have a valid iSpyConnect license/subscription to activate these features. Do NOT attempt to bypass or spoof licensing.

Supported features:
- Secured Remote Access
- Rich Push Notifications
- Email Notifications
- HD/4K Playback
- Cloud Uploads
- Smart Home Integration
- User Permissions
- RTMP Streaming
- Software Updates
- Virtual Reality Support
- Built-in AI

See the individual markdown files in this directory for instructions on configuring each feature.
""",
    "docs/CLOUDFLARE_ACCESS.md": """# Secured Remote Access via Cloudflare

1. Configure a Cloudflare Tunnel pointing to `http://127.0.0.1:9292`.
2. Do NOT expose this tunnel publicly.
3. Apply a Cloudflare Access policy (Zero Trust) restricting access to your authorized emails.
4. If you have an Agent DVR Pro license, you can also use the native iSpyConnect Remote Access feature.
""",
    "docs/EMAIL_NOTIFICATIONS.md": """# Email Notifications

1. Purchase an Agent DVR Pro license.
2. Edit `.env.pro` and provide your SMTP details (`SMTP_HOST`, `SMTP_USER`, etc.).
3. **CRITICAL**: Never commit `.env.pro` or real passwords to version control.
4. Configure Agent DVR UI to use these SMTP details for alert emails.
""",
    "docs/USER_PERMISSIONS.md": """# User Permissions

1. Protect the web interface behind Cloudflare Access for network-level user restriction.
2. For local Agent DVR permissions, purchase a Pro license to enable Local Users in the Agent DVR Server settings.
""",
    "docs/AI_SETUP.md": """# Built-in AI Setup

1. AI features (like object recognition) are built into Agent DVR but require a valid Pro license for full integration.
2. Start by configuring your primary camera (`/dev/video0`) with the CPU Decoder to ensure stability before attempting GPU acceleration.
""",
    "docs/RTMP_STREAMING.md": """# RTMP Streaming

1. RTMP streaming requires a Pro license.
2. Enter your RTMP URL and Stream Key into the Agent DVR UI.
3. Keep your `RTMP_STREAM_KEY` in `.env.pro`. Never commit stream keys to the repository.
""",
    "docs/SMART_HOME.md": """# Smart Home Integration

1. Agent DVR Pro supports robust MQTT and Webhook integrations.
2. Refer to the `home-assistant/` directory for example configurations for Webhooks and MQTT sensors.
""",
    "docs/CLOUD_BACKUP.md": """# Cloud Backup

1. Agent DVR Pro includes built-in cloud uploads.
2. As a fallback, this repository includes an `rclone` based backup script (`scripts/cloud-backup.sh`) to synchronize your `/opt/zeye/media` directory to cloud storage.
""",
    "docs/LICENSE_FEATURES.md": """# License Features

- **Rich Push Notifications**: Setup via the Agent DVR mobile app or iSpyConnect portal.
- **HD/4K Playback**: Ensure your network and hardware can handle the bandwidth. Requires a Pro license for high-res web playback.
- **VR Support**: Enable VR mode in the Agent DVR UI if licensed and supported by your client device.
""",
    "scripts/cloud-backup.sh": """#!/bin/bash
set -e
echo "Starting rclone cloud backup for /opt/zeye/media..."
# Requires rclone configured on the host
rclone sync /opt/zeye/media remote:backup/zeye/media --progress || echo "rclone backup failed or not configured."
echo "Backup routine finished."
""",
    "scripts/mqtt-test.sh": """#!/bin/bash
set -e
echo "Testing MQTT connection..."
# Use mosquitto_pub or similar tool if installed
echo "MQTT test script placeholder."
""",
    "scripts/update-agentdvr.sh": """#!/bin/bash
set -e
echo "Backing up docker-compose.yml before update..."
cp docker-compose.yml "docker-compose.yml.backup-$(date +%s)" || true

echo "Pulling latest agentdvr image..."
docker compose pull agentdvr

echo "Restarting container to apply updates..."
docker compose up -d

echo "Update complete."
""",
    "rclone/README.md": """# Rclone Backup

Use the `scripts/cloud-backup.sh` script to sync your local Agent DVR media to cloud storage.
You must run `rclone config` on your host machine to set up the `remote` destination.
""",
    "home-assistant/README.md": """# Home Assistant Integration

This folder contains example YAML snippets for integrating zEye Agent DVR with Home Assistant.
These integrations utilize MQTT and Webhooks, which are fully supported under the Agent DVR Pro license.
""",
    "home-assistant/zeye-motion-webhook.example.yaml": """# Home Assistant Automation: Webhook Trigger for Motion
alias: "zEye Motion Alert"
trigger:
  - platform: webhook
    webhook_id: zeye_motion_alert_token_placeholder
action:
  - service: notify.notify
    data:
      message: "Motion detected on zEye CCTV!"
""",
    "home-assistant/mqtt-sensor.example.yaml": """# Home Assistant MQTT Sensor Example
mqtt:
  sensor:
    - name: "zEye Camera 1 Status"
      state_topic: "agentdvr/camera1/status"
      value_template: "{{ value_json.state }}"
"""
}

for path, content in files.items():
    full_path = os.path.join("/home/zeazdev/zeye", path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    if full_path.endswith(".sh"):
        os.chmod(full_path, os.stat(full_path).st_mode | stat.S_IEXEC)
