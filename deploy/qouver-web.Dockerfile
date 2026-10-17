# Stage 1: Build static web output
FROM node:24-alpine AS builder

WORKDIR /app
RUN npm install -g pnpm@11

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/ ./packages/
COPY apps/web/ ./apps/web/

RUN pnpm install --frozen-lockfile
RUN pnpm --filter @qouver/api-client gen
RUN pnpm --filter @qouver/web build

# Stage 2: Serve static output with Caddy
FROM caddy:2.9-alpine

COPY --from=builder /app/apps/web/build /srv
COPY deploy/Caddyfile.qouver-web.docker /etc/caddy/Caddyfile

EXPOSE 80
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
