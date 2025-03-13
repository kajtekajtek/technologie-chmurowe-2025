#!/bin/sh

CONTAINER_NAME="my_node_nginx_container"
IMAGE_NAME="my_node_nginx_image"

generate_dockerfile() {
  cat <<'EOF' > Dockerfile
FROM node:18-slim

# install necessary packages
RUN apt-get update && \
    apt-get install -y curl ca-certificates gnupg lsb-release openssl nginx && \
    rm -rf /var/lib/apt/lists/*

# set working directory
WORKDIR /app

# create simple Node.js app
RUN mkdir -p /app
COPY app.js /app/app.js

# generate self-signed SSL certificate
RUN mkdir -p /etc/ssl/private && mkdir -p /etc/ssl/certs && \
    openssl req -newkey rsa:2048 -nodes -keyout /etc/ssl/private/selfsigned.key \
    -x509 -days 365 -out /etc/ssl/certs/selfsigned.crt \
    -subj "/C=PL/ST=Test/L=Test/O=Test/OU=IT/CN=localhost"

# configure Nginx
# cache directory: /var/cache/nginx
# proxy from 80 / 443 to localhost:3000
# config file: /etc/nginx/conf.d/default.conf
RUN adduser --system --no-create-home --group --disabled-login nginx
RUN mkdir -p /var/cache/nginx && chown -R nginx:nginx /var/cache/nginx

# create Nginx config
RUN rm -f /etc/nginx/sites-enabled/default && rm -f /etc/nginx/conf.d/default.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# expose ports
EXPOSE 80 443

# run entrypoint script
CMD ["/entrypoint.sh"]
EOF
}

generate_node_app() {
  cat <<'EOF' > app.js
const http = require('http');

const PORT = 3000;

const requestHandler = (req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hello from Node.js on port 3000!\n');
};

const server = http.createServer(requestHandler);

server.listen(PORT, () => {
  console.log(`Node app listening on port ${PORT}`);
});
EOF
}

generate_nginx_config() {
  cat <<'EOF' > default.conf
proxy_cache_path /var/cache/nginx keys_zone=mycache:10m
                 max_size=100m
                 inactive=60m
                 use_temp_path=off;

server {
    listen 80;
    server_name localhost;

    # Przekierowanie HTTP -> HTTPS (opcja)
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/ssl/certs/selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/selfsigned.key;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_cache mycache;
        proxy_cache_valid 200 30s;
    }
}
EOF
}

generate_entrypoint() {
  cat <<'EOF' > entrypoint.sh
#!/usr/bin/env bash

node /app/app.js &

sleep 1

exec nginx -g 'daemon off;'
EOF
}

build_image() {
  echo "Generating Node.js app, Nginx config, entrypoint script and Dockerfile..."
  generate_node_app
  generate_nginx_config
  generate_entrypoint
  generate_dockerfile

  echo "Building docker image: ${IMAGE_NAME}"
  docker build -t "${IMAGE_NAME}" .
}

run_container() {
  # remove existing container if exists
  if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi

  # run container
  echo "Running the container: ${CONTAINER_NAME}"
  docker run -d \
    --name "${CONTAINER_NAME}" \
    -p 80:80 \
    -p 443:443 \
    "${IMAGE_NAME}"

  sleep 2
  echo "Container is running. Available at:"
  echo " - http://localhost (redirects to HTTPS)"
  echo " - https://localhost (Node.js app)"
}

run() {
  build_image
  run_container
}

run_tests() {
  echo "Tests:"

  
  echo "Checking the HTTP and HTTPS responses..."
  sleep 2
  HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
  HTTPS_CONTENT=$(curl -s --insecure https://localhost)

  if [ "$HTTP_RESPONSE" == "301" ]; then
    echo "OK: HTTP returns a redirect to HTTPS. Code: $HTTP_RESPONSE"
  else
    echo "FAIL: HTTP does not return a redirect to HTTPS. Code: $HTTP_RESPONSE"
    cleanup
    exit 1
  fi

  # Check if HTTPS response contains the expected message
  if [[ "$HTTPS_CONTENT" == *"Hello from Node.js on port 3000!"* ]]; then
    echo "OK: Expected response from the Node.js app (HTTPS)."
  else
    echo "FAIL: Unexpected response from the Node.js app (HTTPS)."
    cleanup
    exit 1
  fi

  # Testy zakończone sukcesem
  cleanup
  echo "Tests passed successfully."
}

# Funkcja sprzątająca (np. na końcu testów)
cleanup() {
  docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
  rm -f Dockerfile default.conf entrypoint.sh app.js
}

run
run_tests