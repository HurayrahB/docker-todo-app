FROM node:24-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm instal --omit=dev
COPY . .
CMD ["node", "src/index.js"]