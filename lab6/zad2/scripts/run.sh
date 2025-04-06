#!/bin/sh
# scripts/run.sh

source "$(dirname $0)/env.sh"

echo "Creating the bridge network..."
# create the bridge network for containers
docker network create --driver bridge $NETWORK

# run the database
$(dirname $0)/run_db.sh

sleep 5

# run the node js app
$(dirname $0)/run_web.sh
