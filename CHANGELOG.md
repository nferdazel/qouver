# Changelog

All notable changes to Qouver are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). An entry is written in
the same commit as the change it describes. Releasing cuts this file automatically: `./task
release` moves everything under `[Unreleased]` beneath the new version heading.

History before this file was added is not reconstructed here. The git history is the record for
those commits.

## [Unreleased]

### Changed

- The e2e and a11y suite runs in Chromium, Firefox and WebKit: `apps/web/playwright.config.ts`
  declares the three projects and CI installs all three browsers.

## [0.1.0] - 2026-11-20

### Changed

- CI/CD v2.0: one local gate (`./task gate`, `./task gate-full`), one release mechanism
  (`./task release`, no push without `--push`), the golden contract job renamed to `preflight`
  and required by every expensive job, and a `VERSION` file that release owns.
- The vendored `ops/scripts/contract-check.sh` is refreshed to the single shared blob.
