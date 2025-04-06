#!/bin/sh
# scripts/run.sh

source ../.env.local

echo "Creating the bridge network..."
# create the bridge network for containers
docker network create --driver bridge $NETWORK

# run the database
./run_db.sh

# run the node js app
./run_web.sh
