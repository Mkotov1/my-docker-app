#!/bin/bash

set -euo pipefail

CONTAINER="version-test"
PORT="8091"
EXPECTED_TEXT="${EXPECTED_TEXT:-My first DevOps project}"

check_http() {
    local expected="$1"
    local attempt

    for attempt in {1..15}; do
        echo "HTTP check attempt: $attempt"

        if curl -fsS --max-time 2 \
            "http://localhost:$PORT/" 2>/dev/null \
            | grep -Fq "$expected"
        then
            echo "HTTP check passed!"
            return 0
        fi

        sleep 1
    done

    echo "HTTP check failed!"
    return 1
}

# Проверяем аргумент
if [[ $# -ne 1 || ! "${1:-}" =~ ^[0-9a-f]{7}$ ]]; then
    echo "Usage: $0 <7-character-commit-sha>"
    exit 2
fi

VERSION="$1"
NEW_IMAGE="ghcr.io/mkotov1/my-docker-app:sha-$VERSION"

# Запоминаем старую версию
OLD_IMAGE=$(sudo docker inspect \
    --format '{{.Config.Image}}' "$CONTAINER")

echo "Old image: $OLD_IMAGE"
echo "New image: $NEW_IMAGE"

# Сначала скачиваем новый образ
sudo docker pull "$NEW_IMAGE"

# Заменяем контейнер
sudo docker stop "$CONTAINER"
sudo docker rm "$CONTAINER"

# Запускаем и проверяем новую версию
if sudo docker run -d \
    --name "$CONTAINER" \
    -p "$PORT:80" \
    "$NEW_IMAGE" &&
check_http "$EXPECTED_TEXT"
then
    echo "Deployment successful!"
else
    echo "Deployment failed! Starting rollback..."

    sudo docker rm -f "$CONTAINER" 2>/dev/null || true

    sudo docker run -d \
        --name "$CONTAINER" \
        -p "$PORT:80" \
        "$OLD_IMAGE"

check_http "My first DevOps project"

    echo "Rollback successful!"
    exit 1
fi
