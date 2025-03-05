#!/usr/bin/bash

IMAGE_NAME="server-image"
CONTAINER_NAME="server"
HOST_PORT=8080
CONTAINER_PORT=8080

# create dockerfile
cat <<EOF > Dockerfile
FROM node:12
WORKDIR /app
COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

# create server.js
cat <<EOF > server.js
const http = require('http');
const port = ${CONTAINER_PORT};

const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.end('Hello World');
});

server.listen(port, () => {
	console.log(\`Server running at http://localhost:\${port}/\`);
});
EOF

# build docker image
echo "Building ${IMAGE_NAME} Docker image"
docker build -t "${IMAGE_NAME}" .
if [ $? -ne 0 ]; then
	echo "Error: couldn't build docker image"
	exit 1
fi

# run the container
echo "Running the ${CONTAINER_NAME} container"
docker rm "${CONTAINER_NAME}" 2> /dev/null

docker run -d -p ${HOST_PORT}:${CONTAINER_PORT} --name ${CONTAINER_NAME} ${IMAGE_NAME}
if [ $? -ne 0 ]; then
	echo "Error: couldn't run the container"
	exit 1
fi

# tests
sleep 3

echo "Is the container running?"
CONTAINER_STATE=$(docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}")
if [ "${CONTAINER_STATE}" == "${CONTAINER_NAME}" ]; then
	echo "OK"
else
	echo "Error: container is not running"
	exit 1
fi

echo "Is the HTTP server returning a proper response?"
RESPONSE=$(curl -s http://localhost:${HOST_PORT})
if [ "${RESPONSE}" == "Hello World" ]; then
	echo "OK"
else
	echo "Error: server returned: ${RESPONSE}. Expected: 'Hello World'"
	exit 1
fi

# clean up
echo "Stopping the container"
docker stop server

echo "Removing the container and the image"
docker rm server
docker rmi server-image
