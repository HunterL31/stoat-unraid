FROM node:20-alpine

WORKDIR /app

# Install dependencies
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install

# Copy application code
COPY . .

EXPOSE 3030

CMD ["node", "server.js"]

