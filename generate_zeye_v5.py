import os
import stat

files = {
    "docs/EMAIL_NOTIFICATIONS.md": """# Email Notifications

Agent DVR supports automated email notifications when motion, sound, or system alerts occur.
**Note**: Native email sending may require an active iSpyConnect Pro license depending on your chosen delivery method.

## Setup Instructions

1. Define your SMTP configuration using the `.env.pro` file.
2. Ensure you only use **placeholders** in your repository. Do NOT commit your real SMTP passwords, tokens, or app passwords.
3. Example `.env.pro` values:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASSWORD=your_app_password_placeholder
   ```
4. Restart your stack and configure the Agent DVR web interface (Server Settings -> SMTP) with the matching variables.
5. In the Agent DVR UI, define **Actions** for your cameras that trigger "Send Email" on Motion Detected or Alert.
""",
    "docs/SMART_HOME.md": """# Smart Home Integration

zEye Agent DVR can deeply integrate with your smart home ecosystem. Agent DVR provides robust Actions that can broadcast MQTT payloads or fire Webhooks to external services like Home Assistant.

## Ecosystem Connectors
- **Home Assistant**: The most flexible integration path. Use Webhooks for instant motion triggers and MQTT for continuous sensor state (like camera connectivity or alarm states).
- **Alexa / Google Home / IFTTT**: You can bridge Agent DVR to Alexa and IFTTT either natively via the iSpyConnect cloud portal (requires subscription) or by proxying triggers through your Home Assistant instance.

## Event Strategy
Instead of constantly polling the camera, you should configure Agent DVR's **Actions** interface to *push* events outwards. For example:
- `IF Camera 1 Detects Motion THEN Call URL: http://homeassistant:8123/api/webhook/zeye_motion_placeholder`
- `IF System Started THEN Publish MQTT: zeye/agentdvr/status = online`

See the `home-assistant/` directory for example YAML blueprints.
""",
    "home-assistant/README.md": """# Home Assistant zEye Configs

This directory provides generic Home Assistant integration templates for zEye.

- **Webhooks**: Fast, simple integrations for triggering automations. Ideal for motion alerts and AI object detection events.
- **MQTT**: Excellent for tracking camera online/offline statuses and reading continuous telemetry.

To use these examples, adapt the placeholders (like `your_secret_webhook_token_placeholder`) to match your Home Assistant configuration and copy the YAML blocks into your `configuration.yaml` or `automations.yaml`.
""",
    "home-assistant/zeye-motion-webhook.example.yaml": """# Add this to your Home Assistant automations.yaml
# Trigger this by configuring an Action in Agent DVR to call the Webhook URL:
# http://<home-assistant-ip>:8123/api/webhook/zeye_front_door_motion_token_placeholder
- id: "zeye_motion_front_door"
  alias: "zEye Motion Alert - Front Door"
  description: "Fires when Agent DVR detects motion on the front door camera."
  mode: single
  trigger:
    - platform: webhook
      webhook_id: "zeye_front_door_motion_token_placeholder"
      allowed_methods:
        - POST
        - GET
      local_only: true
  action:
    - service: notify.notify
      data:
        title: "CCTV Alert"
        message: "Motion was detected at the Front Door."
""",
    "home-assistant/mqtt-sensor.example.yaml": """# Add this to your Home Assistant configuration.yaml
# It monitors the MQTT topic for the camera's system state.
mqtt:
  sensor:
    - name: "zEye Front Door Status"
      state_topic: "zeye/agentdvr/frontdoor/status"
      value_template: "{{ value_json.state }}"
      json_attributes_topic: "zeye/agentdvr/frontdoor/attributes"
      device_class: connectivity
""",
    "scripts/mqtt-test.sh": """#!/bin/bash
set -e

echo "Starting MQTT diagnostic test..."

# Read from .env.pro if it exists
if [ -f "/home/zeazdev/zeye/.env.pro" ]; then
    echo "Sourcing .env.pro..."
    # Safely source to ignore non-assignment lines
    export $(grep -v '^#' /home/zeazdev/zeye/.env.pro | xargs 2>/dev/null) || true
fi

MQTT_PREFIX="zeye/agentdvr"
MQTT_HOST=${MQTT_HOST:-"127.0.0.1"}

echo "Using MQTT Broker: $MQTT_HOST"
echo "Publishing to topic prefix: $MQTT_PREFIX/test"

if command -v mosquitto_pub >/dev/null 2>&1; then
    mosquitto_pub -h "$MQTT_HOST" -t "$MQTT_PREFIX/test" -m '{"status":"online", "message":"zEye MQTT diagnostic run"}' || echo "MQTT publish failed. Check broker."
    echo "Test message published."
else
    echo "mosquitto_pub tool not found. Install mosquitto-clients to perform live MQTT testing."
fi

echo "Diagnostic complete."
"""
}

for path, content in files.items():
    full_path = os.path.join("/home/zeazdev/zeye", path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    if full_path.endswith(".sh"):
        os.chmod(full_path, os.stat(full_path).st_mode | stat.S_IEXEC)
