FROM node:20-slim

ENV NODE_ENV="production"
ENV APP_NAME="etl-worker"

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 8080
CMD ["node", "app.js"]
