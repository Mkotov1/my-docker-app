#!/bin/bash

echo "===== Check started: $(date '+%Y-%m-%d %H:%M:%S') ====="

CONTAINER="my-docker-app-web-1"

echo "Checking Docker container..."

if /usr/bin/docker inspect --format '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -qx true; then
    echo "Container is running"
else
    echo "ERROR: Container is not running"
    exit 1
fi

echo "Checking website..."

if /usr/bin/curl -fs -o /dev/null --max-time 5 http://localhost:8084; then
    echo "Website is working"
    exit 0
else
    echo "ERROR: Website is not working"
    exit 1
fi
