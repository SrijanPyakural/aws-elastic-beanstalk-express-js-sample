# Dockerfile for the AWS Elastic Beanstalk Express sample (Node 16)
FROM node:16

# Create app directory
WORKDIR /app

# Install only what's needed
COPY package*.json ./
# Prefer lockfile if present; otherwise fall back to npm install
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm install --production; \
    fi

# Copy the rest of the source
COPY . .

# Environment & port (sample app listens on PORT or 8080)
ENV NODE_ENV=production
EXPOSE 8080

# Start the app
# If your package.json has "start": "node app.js", this will work.
# If not, either add that script or change this CMD to ["node", "app.js"].
CMD ["npm", "start"]

