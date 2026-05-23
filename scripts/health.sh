#!/bin/bash
set -e

temp_dir=$(mktemp -d)
cp docker-compose.yml "$temp_dir/"
if docker compose -f "$temp_dir/docker-compose.yml" config > "$temp_dir/config_out" 2>&1; then
    sed 's/static-auth-secret.*/static-auth-secret: <REDACTED>/g' "$temp_dir/config_out"
else
    cat "$temp_dir/config_out"
    rm -rf "$temp_dir"
    exit 1
fi
rm -rf "$temp_dir"

echo "Host IPs:"
hostname -I || ip addr show

echo "Testing HTTP on localhost:"
curl -s -o /dev/null -w "127.0.0.1 HTTP %{http_code}\n" http://127.0.0.1:9292 || true

echo "Testing HTTP on LAN:"
for ip in $(hostname -I); do
    curl -m 2 -s -o /dev/null -w "$ip HTTP %{http_code}\n" http://$ip:9292 || true
done

echo "Listing /dev/video*:"
ls -l /dev/video* || true

echo "Camera probe:"
if docker compose ps | grep -q "zeye-agentdvr"; then
    probe_output=$(docker compose exec -T agentdvr ffmpeg -hide_banner -f v4l2 -list_formats all -i /dev/video0 2>&1 || true)
    echo "$probe_output"
    if echo "$probe_output" | grep -q "Immediate exit requested"; then
        echo "Format probe completed normally (Immediate exit requested is expected)."
    fi
fi
