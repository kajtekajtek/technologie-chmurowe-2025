FROM node:18

RUN apt-get update && apt-get install -y iputils-ping && rm -rf /var/lib/apt/lists/*

CMD ["tail", "-f", "/dev/null"]
