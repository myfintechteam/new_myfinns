# -------------------------
# 1. Base Image
# -------------------------
FROM node:18-slim

# Set working directory
WORKDIR /app

# -------------------------
# 2. Install system dependencies
# -------------------------
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# 3. Copy package files and install dependencies
# -------------------------
COPY package*.json ./
RUN npm install --production

# -------------------------
# 4. Copy application source code
# -------------------------
COPY . .

# -------------------------
# 5. Environment settings
# -------------------------
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# -------------------------
# 6. Expose app port
# -------------------------
EXPOSE 3000

# -------------------------
# 7. Start server
# -------------------------
CMD ["node", "server.js"]
