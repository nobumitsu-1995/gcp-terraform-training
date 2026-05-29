# processing-svc/Dockerfile
FROM node:20-slim

ENV APP_NAME="processing-svc"
ENV NODE_ENV="production"

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

EXPOSE 8080
CMD ["node", "app.js"]
