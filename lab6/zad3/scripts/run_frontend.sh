#!/bin/sh

set -e

source "$(dirname $0)/env.sh"

echo "Building the $FRONTEND_IMAGE Docker image..."
docker build -t "$FRONTEND_IMAGE" "$(dirname $0)/../frontend"

echo "Starting the $FRONTEND_CONTAINER Docker container..."
docker run -d \
    --name "$FRONTEND_CONTAINER" \
    --network "$FRONTEND_NETWORK" \
    -p "$FRONTEND_HOST_PORT":"$FRONTEND_CONTAINER_PORT" \
    "$FRONTEND_IMAGE"
