#!/bin/sh

CONTAINER_NAME="my_nginx_container"

read -p "Enter the message to be returned by the server: " message

# generate custom nginx config
echo "Creating custom nginx config..."
cat <<EOF > custom_nginx.conf
server {
    listen 80;
    server_name localhost;

    location / {
        return 200 "$message";
    }
}
EOF

# if container exists, remove it
if [ "$(docker ps -a | grep $CONTAINER_NAME)" ]; then
    echo "Removing container..."
    docker rm -f $CONTAINER_NAME
fi

# run container
docker run -d --name "$CONTAINER_NAME" \
    -p 80:80 \
    -v "$(pwd)/custom_nginx.conf:/etc/nginx/conf.d/custom.conf:ro" \
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
if [ "$RESPONSE" = "$message" ]; then
    echo "Response from the server: ${RESPONSE} (correct)"
else
    echo "Response from the server: ${RESPONSE} (incorrect)"
fi

# clean up
rm custom_nginx.conf
docker rm -f $CONTAINER_NAME > /dev/null 2>&1 || true