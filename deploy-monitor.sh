#!/bin/bash

echo "Starting Docker Monitor deployment..."

SOURCE="monitoring/monitor.sh"
DESTINATION="/opt/docker-monitor/monitor.sh"
BACKUP="/opt/docker-monitor/monitor.sh.bak"

if [ -f "monitoring/monitor.sh" ]; then
    echo "Source file found"
else
    echo "ERROR: Source file not found"
    exit 1
fi

if bash -n monitoring/monitor.sh; then
    echo "Bash syntax OK"
else
    echo "ERROR: Bash syntax check failed"
    exit 1
fi
echo "Source: $SOURCE"
echo "Destination: $DESTINATION"
echo "Backup: $BACKUP"

echo "Creating backup..."

if sudo cp "$DESTINATION" "$BACKUP"; then
    echo "Backup created successfully"
else
    echo "ERROR: Backup failed"
    exit 1
fi

echo "Installing new monitor version..."

if sudo install -o root -g root -m 700 "$SOURCE" "$DESTINATION"; then
    echo "Monitor installed successfully"
else
    echo "ERROR: Installation failed"
    echo "Attempting rollback..."

if sudo install -o root -g root -m 700 "$BACKUP" "$DESTINATION"; then
    echo "Previous version restored"

    if sudo "$DESTINATION"; then
        echo "Restored monitor is working"
    else
        echo "CRITICAL: Restored monitor is not working!"
    fi
else
    echo "CRITICAL: Rollback failed!"
fi

    exit 1
fi

echo "Verifying installed monitor..."

if sudo "$DESTINATION"; then
    echo "Deployment completed successfully!"
else
    echo "ERROR: Monitor verification failed"
    echo "Rolling back to previous version..."

    if sudo cp "$BACKUP" "$DESTINATION"; then
        echo "Rollback completed successfully"

        echo "Verifying restored monitor..."

        if sudo "$DESTINATION"; then
            echo "Restored monitor is working"
        else
            echo "CRITICAL: Restored monitor is not working!"
        fi
    else
        echo "CRITICAL: Rollback failed!"
    fi

    exit 1
fi
