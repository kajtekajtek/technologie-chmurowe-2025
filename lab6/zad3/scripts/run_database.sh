#!/bin/sh

set -e

source "$(dirname $0)/env.sh"

echo "Building the $DB_IMAGE Docker image..."
docker build -t "$DB_IMAGE" "$(dirname $0)/../database"

echo "Starting the $DB_CONTAINER Docker container..."
docker run -d \
    --name "$DB_CONTAINER" \
    --network "$BACKEND_NETWORK" \
    -e MYSQL_ROOT_PASSWORD="$DB_PASSWORD" \
    -e MYSQL_DATABASE="$DB_NAME" \
    "$DB_IMAGE"
