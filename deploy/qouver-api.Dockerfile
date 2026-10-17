# Stage 1: Build Nim binary
FROM nimlang/nim:2.2.0-alpine AS builder

WORKDIR /app
RUN apk add --no-cache postgresql-dev gcc musl-dev git

COPY qouver.nimble ./
RUN nimble install -y -d

COPY shared/ ./shared/
COPY apps/api/ ./apps/api/

RUN nim c -d:release --opt:speed --hints:off --warnings:on \
    -p:shared -p:apps/api/src \
    -o:/app/qouver-api apps/api/src/main.nim

# Stage 2: Runtime image
FROM alpine:3.21

WORKDIR /app
RUN apk add --no-cache libpq ca-certificates

COPY --from=builder /app/qouver-api /app/qouver-api

EXPOSE 8091
ENTRYPOINT ["/app/qouver-api"]
CMD ["--role=api", "--host=0.0.0.0", "--port=8091"]
