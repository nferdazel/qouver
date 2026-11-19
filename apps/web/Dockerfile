# qouver web: the static SvelteKit tree, served by nginx.
#
# Build context is the repo root (podman build -f apps/web/Dockerfile .).
#
# Two stages so the runtime image carries nginx and the built files only: no node,
# no pnpm store, no source. The build stamps the commit into /healthz, which is the
# check the deploy script reads before it calls a deploy good (DEPLOY-FLOW.md §13.5).

FROM docker.io/library/node:24-alpine AS builder

# pnpm comes from corepack at the version the root package.json pins, so an image
# built here and an image built in CI resolve the lockfile the same way.
RUN corepack enable

WORKDIR /src

# Manifests and workspace packages first: a change to apps/web alone reuses this
# layer instead of reinstalling every dependency again.
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY packages/ ./packages/
COPY apps/web/package.json apps/web/

RUN pnpm install --frozen-lockfile --filter @qouver/web...

COPY apps/web/ ./apps/web/

RUN pnpm --filter @qouver/web build

# Distinct content per commit: two commits never produce the same image, so :prev
# is always a usable rollback target and /healthz names the revision that answered.
ARG GIT_REV=dev
RUN printf '{"rev":"%s","part":"web"}\n' "$GIT_REV" > apps/web/build/healthz

FROM docker.io/library/nginx:1.30.7-alpine

COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /src/apps/web/build/ /usr/share/nginx/html/

EXPOSE 8080
