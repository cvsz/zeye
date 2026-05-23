#!/bin/bash
set -e

echo "=== System Resource Diagnostic Tool ==="
echo ""

echo "[ Uptime ]"
uptime
echo ""

echo "[ CPU Cores Available ]"
nproc
echo ""

if command -v lscpu >/dev/null 2>&1; then
    echo "[ CPU Architecture Summary ]"
    lscpu | grep -E "^(Model name|Architecture|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket|Socket\(s\))" || true
    echo ""
fi

echo "[ System Memory ]"
free -h
echo ""

echo "[ Storage Availability (/opt/zeye) ]"
df -h /opt/zeye 2>/dev/null || df -h /
echo ""

echo "[ Docker Container Stats (zeye-agentdvr) ]"
if docker ps --format '{{.Names}}' | grep -q "^zeye-agentdvr$"; then
    docker stats --no-stream zeye-agentdvr
else
    echo "zeye-agentdvr container is NOT currently running!"
fi
echo ""
echo "======================================="
