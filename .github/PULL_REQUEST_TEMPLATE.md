## What changed

<!-- One paragraph. What changed and why. Link the issue if there is one. -->

## Checks run

- [ ] `./task check` — result:
- [ ] `./task test` (or `./task ci` when the change touches the contract, the site, or deploy)
- [ ] `./ops/scripts/contract-check.sh .` — violations:
- [ ] dependency scan for the ecosystem touched (`pnpm audit --audit-level=high` for the web app)
- [ ] `./task e2e` when a route, the design tokens or the accessibility surface changed

## Scope

- [ ] One pull request, one reason
- [ ] No new dependency, or the reason it is worth one:
- [ ] `packages/contracts` and the generated client are in step
- [ ] Docs updated in this change if behaviour changed
- [ ] Nothing in the diff carries a credential, token, `.env` file or connection string
