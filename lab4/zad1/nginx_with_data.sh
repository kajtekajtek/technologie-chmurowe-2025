#!/bin/sh

# create volume
docker volume create nginx_data

# add index.html to volume
docker run --rm -v nginx_data:/usr/share/nginx/html \
    bash:5.1 \
    bash -c 'echo "Hello world!" > /usr/share/nginx/html/index.html'

# run the container
echo "Running the nginx container"
docker run --rm -d --name my_nginx -p 8080:80 \
    -v nginx_data:/usr/share/nginx/html \
    nginx

# change the index.html contents through volume
docker run --rm -v nginx_data:/usr/share/nginx/html \
    bash:5.1 \
    bash -c 'echo "<h1>Wello Horld!</h1>" > /usr/share/nginx/html/index.html'