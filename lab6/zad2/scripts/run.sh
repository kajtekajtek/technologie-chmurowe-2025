#!/bin/sh
# scripts/run.sh

# create the bridge network for containers
docker network create --driver bridge my_network

# run the database
./run_db.sh

# run the node js app
./run_web.sh
