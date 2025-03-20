#!/bin/sh

# create nodejs_data volume
docker volume create nodejs_data

# add index.js to the volume
docker run --rm -v nodejs_data:/app busybox sh -c \
    'echo "Hello from Node.js volume" > /app/index.js'

# run the nodejs container
docker run --rm -d --name my_node \
    -v nodejs_data:/app \
    node:latest \

# create all_volumes volume
docker volume create all_volumes

# copy files from nginx_data to all_volumes
docker run --rm \
    -v nginx_data:/usr/share/nginx/html \
    -v all_volumes:/mnt/all_volumes \
    busybox \
    sh -c "cp -r /usr/share/nginx/html /mnt/all_volumes"

# copy files from nodejs_data to all_volumes
docker run --rm \
    -v nodejs_data:/app \
    -v all_volumes:/mnt/all_volumes \
    busybox \
    sh -c "cp -r /app /mnt/all_volumes"

# check the all_volumes contents
echo "all_volumes contents:"
docker run --rm -v all_volumes:/mnt/all_volumes busybox ls -l /mnt/all_volumes