FROM node:18-alpine

# set work directory
WORKDIR /usr/src/app

# copy dependencies
COPY package.json ./
RUN npm install --production

# copy source code
COPY . .

# expose port
EXPOSE 3000

# GET /health every 30s, wait max 5s and do max 3 retries
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["npm", "start"]
