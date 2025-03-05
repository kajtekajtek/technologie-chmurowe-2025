#!/bin/sh

IMAGE_NAME="server-image"
CONTAINER_NAME="server"
HOST_PORT=8080
CONTAINER_PORT=8080

# create dockerfile
cat <<EOF > Dockerfile
FROM node:14
WORKDIR /app
COPY server.js .
RUN npm install express
EXPOSE 8080
CMD ["node", "server.js"]
EOF

# create server.js
cat <<EOF > server.js
const express = require('express');
const app = express();
const port = ${CONTAINER_PORT};

app.get('/', (req, res) => {
  const currentDate = new Date();
  res.status(200).send(\`\${currentDate}\`);
});

app.listen(port, () => {
  console.log(\`Server running at: \${port}/\`);
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

RESPONSE=$(curl -s http://localhost:8080)
echo "Server responded with: ${RESPONSE}"

# clean up
echo "Stopping the container"
docker stop ${CONTAINER_NAME}

echo "Removing the container and the image"
docker rm ${CONTAINER_NAME}
docker rmi ${IMAGE_NAME}