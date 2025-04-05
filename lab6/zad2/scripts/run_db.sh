#!/bin/sh
# scripts/run_db.sh

docker run -d \
    --name db \
    --network my_network \
    -e MYSQL_ROOT_PASSWORD=secret \
    -e MYSQL_DATABASE=testdb \
    mysql:8.0
