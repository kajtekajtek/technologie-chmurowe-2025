#!/bin/sh

set -e

source "$(dirname $0)/env.sh"

echo "Building the $BACKEND_IMAGE Docker image..."
docker build -t "$BACKEND_IMAGE" "$(dirname $0)/../backend"

echo "Starting the $BACKEND_CONTAINER Docker container..."
docker run -d \
    --name "$BACKEND_CONTAINER" \
    --network "$FRONTEND_NETWORK" \
    -p "$BACKEND_HOST_PORT":"$BACKEND_CONTAINER_PORT" \
    "$BACKEND_IMAGE"

docker network connect "$BACKEND_NETWORK" "$BACKEND_CONTAINER"
