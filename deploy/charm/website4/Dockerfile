# Build stage
FROM oven/bun:1 AS build

# Set CI environment for pnpm
ENV CI=true

COPY . /app
WORKDIR /app

# Install dependencies and build
RUN bun install --frozen-lockfile --production
RUN bun run build

# Production stage - use nginx for high-performance static file serving
FROM nginx:alpine

# Copy built static files from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
