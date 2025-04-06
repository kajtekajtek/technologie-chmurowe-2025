#!/bin/sh
# scripts/run_web.sh

source ../.env.local

cd ../app/

echo "Building the $APP_IMAGE image..."
docker build -t $APP_IMAGE --build-arg PORT=$PORT .

echo "Running the $APP_HOST container..."
docker run -d \
    --name $APP_HOST \
    --network $NETWORK \
    -p $PORT:$PORT \
    -e DB_HOST=$DB_HOST \
    -e DB_USER=$DB_USER \
    -e DB_PASSWORD=$DB_PASSWORD \
    -e DB_NAME=$DB_NAME \
    $APP_IMAGE
