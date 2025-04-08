#!/bin/sh

source "$(dirname $0)/env.sh"

echo "Stopping the running containers..."
docker stop "$FRONTEND_CONTAINER" "$BACKEND_CONTAINER" "$DB_CONTAINER" || true

echo "Removing the containers..."
docker rm "$FRONTEND_CONTAINER" "$BACKEND_CONTAINER" "$DB_CONTAINER" || true

echo "Removing the Docker networks..."
docker network rm "$FRONTEND_NETWORK" "$BACKEND_NETWORK" || true

echo "Removing the Docker images..."
docker image rm "$FRONTEND_IMAGE" "$BACKEND_IMAGE" "$DB_IMAGE" || true
