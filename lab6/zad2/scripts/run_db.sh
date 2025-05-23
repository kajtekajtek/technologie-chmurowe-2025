#!/bin/sh
# scripts/run_db.sh

source "$(dirname $0)/env.sh"

echo "Running the database container..."
docker run -d \
    --name $DB_HOST \
    --network $NETWORK \
    -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD \
    -e MYSQL_DATABASE=$DB_NAME \
    mysql:8.0
