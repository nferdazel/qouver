# Stage 1: Build Nim binary
FROM docker.io/nimlang/nim:2.2.4-alpine AS builder

WORKDIR /app
RUN apk add --no-cache postgresql-dev gcc musl-dev git

COPY qouver.nimble ./
RUN nimble install -y -d

# Commit being built, stamped into the binary so /healthz reports it and each
# commit yields a distinct image ID (a usable :prev for rollback). CI also puts
# this SHA in org.opencontainers.image.revision, so a published image can be
# matched to the ref the host deployed without starting the container.
#
# An image that exits before it reports READY makes `systemctl restart` return
# non-zero at once; the host deploy logs that as a warning and lets the health
# gate decide (QOUVER_CICD_STANDARD v1.1 rule 8), so this label is what the gate
# compares against after a restart it did not trust.
ARG GIT_REV=dev

COPY config.nims ./
COPY vendor/ ./vendor/
COPY shared/ ./shared/
COPY apps/api/ ./apps/api/

RUN nim c -d:release -d:GitRev="${GIT_REV}" --opt:speed --hints:off --warnings:on \
    -p:shared -p:apps/api/src \
    -o:/app/qouver-api apps/api/src/main.nim

# Stage 2: Runtime image
FROM docker.io/library/alpine:3.24

WORKDIR /app
RUN apk add --no-cache libpq ca-certificates

COPY --from=builder /app/qouver-api /app/qouver-api

EXPOSE 8091
ENTRYPOINT ["/app/qouver-api"]
CMD ["--role=api", "--host=0.0.0.0", "--port=8091"]
