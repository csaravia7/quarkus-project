# Base glibc (no alpine/musl) para compatibilidad con OneAgent PaaS flavor default
FROM node:20-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY src ./src
COPY public ./public
EXPOSE 3000
USER node
CMD ["node", "src/server.js"]
