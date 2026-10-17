# Qouver

**Umbrella home for systems and ideas.**

Official monorepo for [qouver.com](https://qouver.com).

## Architecture & Stack

- **Backend (`apps/api`):** Nim 2.2 + [Mummy](https://github.com/guzba/mummy) (HTTP/WebSocket) + PostgreSQL (`db_connector`).
- **Frontend (`apps/web`):** SvelteKit 3 + Svelte 5 (Runes) + TypeScript + `@sveltejs/adapter-static` (Zero-JS/SSG pre-rendered HTML routes with full SEO & WCAG 2.2 AA accessibility).
- **Contracts (`packages/contracts`):** OpenAPI 3.1 specification for single source of truth.
- **Orchestration (`./task`):** Single-door POSIX runner for checks, tests, builds, and CI verification.
- **Design System:** "Workshop Broadsheet" — bone paper (`#EDEAE3`), ink (`#141311`), oxide accent (`#B23A1A`), self-hosted Fraunces & Archivo fonts.

## Directory Structure

```text
apps/
  api/               # Nim backend service (Mummy + PostgreSQL)
  web/               # SvelteKit presentation layer (adapter-static)
packages/
  contracts/         # OpenAPI 3.1 specification (qouver-api.yaml)
  api-client/        # Generated TypeScript client
  ui/                # Shared Broadsheet design tokens & Svelte components
shared/
  kernel/            # Common domain types and helpers
deploy/              # Caddy & Podman Quadlet configurations
tools/               # Build and verification tools
task                 # Single-door POSIX task runner
```

## Quick Start

```sh
./task check         # Static analysis, formatting check, and contracts
./task test          # Run unit and integration tests
./task build         # Build Nim API binary and SvelteKit static site
./task ci            # Run complete gate suite
```
