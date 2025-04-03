#!/bin/sh

SUBNET="192.168.1.0/24"
GATEWAY="192.168.1.1"
NETWORK_NAME="my_bridge"
CONTAINER_NAME="test-container"

cleanup()
{
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    docker network rm $NETWORK_NAME 
}
trap cleanup EXIT
trap cleanup HUP
trap cleanup QUIT

docker network create \
    --driver bridge \
    --subnet $SUBNET \
    --gateway $GATEWAY \
    $NETWORK_NAME

# detached, interactive & allocate a pseudo-TTY
docker run -dit --name $CONTAINER_NAME \
    --network $NETWORK_NAME \
    alpine sh

docker exec -it $CONTAINER_NAME sh
