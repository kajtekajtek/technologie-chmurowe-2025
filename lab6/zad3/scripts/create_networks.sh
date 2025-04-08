#!/bin/sh

set -e

source "$(dirname $0)/env.sh"

echo "Creating $FRONTEND_NETWORK Docker network..."
docker network create --driver bridge "$FRONTEND_NETWORK" || true

echo "Creating $BACKEND_NETWORK Docker network..."
docker network create --driver bridge "$BACKEND_NETWORK" || true
