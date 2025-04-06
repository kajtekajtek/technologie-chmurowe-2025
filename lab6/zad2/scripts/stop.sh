#!/bin/sh
# scripts/stop.sh

source ../.env.local

echo "Stopping the running containers..."
docker stop $DB_HOST $APP_HOST
echo "Removing containers..."
docker rm $DB_HOST $APP_HOST
echo "Removing the network..."
docker network rm $NETWORK
echo "Removing the $APP_IMAGE image..."
docker image rm $APP_IMAGE
