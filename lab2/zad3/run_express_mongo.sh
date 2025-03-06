#!/bin/sh

NODE_CONTAINER="node-container"
MONGO_CONTAINER="mongo-container"
IMAGE_NAME="express-mongo-img"
NETWORK_NAME="express-mongo-net"
NODE_VERSION=16
HOST_PORT=8080
CONTAINER_PORT=8080

mkdir -p express_mongo_app
cd express_mongo_app

# dockerfile
cat <<EOF > Dockerfile
FROM node:${NODE_VERSION}
WORKDIR /app
COPY package.json .
RUN npm install
COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

# package.json
cat <<EOF > package.json
{
    "name": "express-mongo-app",
    "version": "1.0.0",
    "description": "lab2 zad3",
    "main": "server.js",
    "dependencies": {
        "express": "^4.17.1",
        "mongodb": "^4.4.1"
    }
}
EOF

# server.js
cat <<EOF > server.js
const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
const port = ${CONTAINER_PORT};

// main endpoint
app.get('/', async (req, res) => {
    try {
        const client = new MongoClient(process.env.MONGO_URL);
        await client.connect();

        const db = client.db('testdb');
        const collection = db.collection('testcol');

        if ((await collection.countDocuments()) === 0) {
            await collection.insertOne({ messagge: "Hello from MongoDB" });
        }

        const data = await collection.find({}).toArray();
        res.json(data);

        await client.close();
    } catch (err) {
        console.error(err);
        res.status(500).send('Error while loading the database');
    }
});

app.listen(port, () => {
    console.log(\`Server is running at \${port}\`);
});
EOF

# build docker image
echo "Building docker image"
docker build -t ${IMAGE_NAME} .

# create docker network
echo "Creating docker network"
docker network ls | grep -q ${NETWORK_NAME} || docker network create ${NETWORK_NAME}

# run the container with mongodb
echo "Running the mongo container"
docker rm -f ${MONGO_CONTAINER} 2>/dev/null || true
docker run -d --network ${NETWORK_NAME} --name ${MONGO_CONTAINER} -p 27017:27017 mongo:latest

# run the container with node.js
echo "Running the node container"
docker rm -f ${NODE_CONTAINER} 2>/dev/null || true
docker run -d -p ${HOST_PORT}:${CONTAINER_PORT} --network ${NETWORK_NAME} --name ${NODE_CONTAINER} -e MONGO_URL="mongodb://${MONGO_CONTAINER}:27017/testdb" ${IMAGE_NAME}

# tests
sleep 5

echo "Checking response code"
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$RESPONSE_CODE" -eq 200 ]; then
    echo "OK"
else
    echo "Error: server responded with ${RESPONSE_CODE}"
fi

echo "Data from the database fetched from the server:"
curl -s http://localhost:8080
echo ""

docker stop ${MONGO_CONTAINER} > /dev/null
docker stop ${NODE_CONTAINER} > /dev/null