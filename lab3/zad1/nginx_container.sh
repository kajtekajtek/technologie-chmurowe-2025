#!/bin/sh

CONTAINER_NAME="my_nginx_container"

# prepare index.html
read -p "Enter the content of index.html: " content
echo $content > index.html

# if container exists, remove it
if [ "$(docker ps -a | grep $CONTAINER_NAME)" ]; then
    echo "Removing container..."
    docker rm -f $CONTAINER_NAME
fi

# run container
docker run -d --name "$CONTAINER_NAME" \
    -p 80:80 \
    -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" \
    nginx:latest

# get container IP address
CONTAINER_IP=$(docker inspect -f \
    '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
    "$CONTAINER_NAME")

echo "Container is running at $CONTAINER_IP"
echo "Web server is available at http://$CONTAINER_IP"
echo "Or at host machine at http://localhost:80"

# Tests
sleep 2

echo "Checking if container is running..."
if [ "$(docker ps | grep $CONTAINER_NAME)" ]; then
    echo "Container is running"
else
    echo "Container is not running"
fi

echo "Checking the site's content..."
RESPONSE=$(curl -s http://localhost:80)
if [ "$RESPONSE" = "$content" ]; then
    echo "Response from the server: ${RESPONSE} (correct)"
else
    echo "Content is incorrect"
fi

# clean up
rm index.html
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true