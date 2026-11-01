#!/bin/bash

cd /home/kotovuser/my-docker-app || exit 1

echo "Cheking Docker container..."
if sudo docker compose ps --status running -q web | grep -q .; then
	echo "Container is running"
else
	echo "Container is stopped"
	echo "Starting container..."
	sudo docker compose up -d web
fi

echo "Checking website..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8084)

for i in 1 2 3 4 5; do
    echo "Checking website. Attempt $i..."

    if curl -fs -o /dev/null --max-time 5 http://localhost:8084; then
        echo "Website is working"
        exit 0
    else
        echo "Website is not ready"

        if [ "$i" -eq 5 ]; then
            echo "ERROR: Website failed after 5 attempts"
            exit 1
        fi

        sleep 2
    fi
done
