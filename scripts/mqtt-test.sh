#!/bin/bash
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
