# Contributing

Qouver is the monorepo for qouver.com: a Nim backend in `apps/api`, a pre-rendered SvelteKit site in
`apps/web`, and shared packages under `packages/`.

## Before you send anything

- Open an issue first for anything larger than a typo. The architecture is deliberate, and a patch
  that changes the contract, the deploy scripts or the design tokens needs the approach agreed before
  it is written.
- Keep changes to one concern per pull request. A contract change and a design change in one diff
  cannot be reviewed together.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`), because the
  history is read by hand and a release note is assembled from it.

## Build and test

| Step | Command | Needs |
|---|---|---|
| Dependencies | `nimble install -y -d` and `pnpm install --frozen-lockfile` | Nim in the `qouver.nimble` range, Node, pnpm |
| Static analysis and contract | `./task check` | libpq headers for the API |
| Unit and contract tests | `./task test` | the same |
| Build binary and pre-render | `./task build` | the same, plus Node |
| The full gate | `./task ci` | Playwright browsers for the e2e and accessibility suite |

`./task ci` is what CI runs, and it is what a pull request must pass before review. A pull request
that changes `apps/api` must also keep `packages/contracts` and the generated client in step: the
contract is the source of truth, and a handler that drifts from it fails `./task check`.

## Branch and pull request

- Branch from `main`, name it after the concern (`fix/health-gate-timeout`, `docs/readme-standard`).
- Open the pull request against `main`, and say in the description which command you ran and what it
  printed. "Tests pass" without the command is not evidence.
- Do not add a dependency without saying in the description why the existing stack cannot do the job.
- Do not touch `ops/webhook/`, the deploy scripts or the Caddy block to make a feature work locally;
  those are the production contract.

## What not to send

- Secrets, tokens, `.env` files, or a real database dump. The repository is public, so a leak is public
  the moment it is pushed.
- Screenshots of the production host, its logs, or any personal data.
- A change that reformats files you did not otherwise touch.
- Generated content: `apps/web` output and the OpenAPI client are build results, not source.

Security reports do not go in an issue: see [`SECURITY.md`](SECURITY.md).
