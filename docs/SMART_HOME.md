# Smart Home Integration

zEye Agent DVR can deeply integrate with your smart home ecosystem. Agent DVR provides robust Actions that can broadcast MQTT payloads or fire Webhooks to external services like Home Assistant.

## Ecosystem Connectors
- **Home Assistant**: The most flexible integration path. Use Webhooks for instant motion triggers and MQTT for continuous sensor state (like camera connectivity or alarm states).
- **Alexa / Google Home / IFTTT**: You can bridge Agent DVR to Alexa and IFTTT either natively via the iSpyConnect cloud portal (requires subscription) or by proxying triggers through your Home Assistant instance.

## Event Strategy
Instead of constantly polling the camera, you should configure Agent DVR's **Actions** interface to *push* events outwards. For example:
- `IF Camera 1 Detects Motion THEN Call URL: http://homeassistant:8123/api/webhook/zeye_motion_placeholder`
- `IF System Started THEN Publish MQTT: zeye/agentdvr/status = online`

See the `home-assistant/` directory for example YAML blueprints.
