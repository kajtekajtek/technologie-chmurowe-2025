FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ARG PORT
EXPOSE ${PORT}
CMD ["npm", "start"]
