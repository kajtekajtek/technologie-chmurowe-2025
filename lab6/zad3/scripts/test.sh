#!/bin/sh

set -e

source "$(dirname $0)/env.sh"

echo "Running tests..."

echo "docker ps"
docker ps

echo "$FRONTEND_CONTAINER ping -c 1 $BACKEND_CONTAINER"
docker exec "$FRONTEND_CONTAINER" ping -c 1 "$BACKEND_CONTAINER"

echo "$BACKEND_CONTAINER ping -c 1 $DB_CONTAINER"
docker exec "$BACKEND_CONTAINER" ping -c 1 "$DB_CONTAINER"

echo "curl -I http://localhost:$FRONTEND_HOST_PORT"
curl -I http://localhost:$FRONTEND_HOST_PORT || true

echo "curl -I http://localhost:$BACKEND_HOST_PORT"
curl -I http://localhost:$BACKEND_HOST_PORT || true

