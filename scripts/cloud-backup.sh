#!/bin/bash
set -e
echo "Starting rclone cloud backup for /opt/zeye/media..."
# Requires rclone configured on the host
rclone sync /opt/zeye/media remote:backup/zeye/media --progress || echo "rclone backup failed or not configured."
echo "Backup routine finished."
