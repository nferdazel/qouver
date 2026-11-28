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

- The API builds on Qummy 0.6.1: `qouver.nimble` pins `#0.6.1` instead of `#0.5.1`, and the Docker
  builder moves from `nimlang/nim:2.2.4-alpine` to `2.2.6-alpine-regular` behind the image digest
  Qummy CI builds with, because 0.6.1 requires Nim 2.2.6 or newer. No runtime behaviour change.
- The API runs on Qummy 0.5.1, our fork of Mummy, installed from its published git tag. The vendored
  copy and `config.nims` are gone, so `qouver.nimble` is the only place a dependency is declared, and
  the loopback regression test now fails unless the imported module resolves to the installed package.
  No runtime behaviour change.
- Site and API copy now match the repositories: Majadu is a Nim 2.4 API on Mummy, not Go;
  its rating model is rolling points, not Glicko; SDS edits in place with an activity log;
  and archived Skyward and M-DEF sit at the bottom of the register.
- `/api/systems/status` no longer lists Skyward (archived, host does not resolve) and reports
  latency as 0 (unmeasured) instead of inventing milliseconds.
- About page credits Fredi, and the README describes the shipped Direction C design system.
- The e2e and a11y suite runs in Chromium, Firefox and WebKit: `apps/web/playwright.config.ts`
  declares the three projects and CI installs all three browsers.

## [0.1.0] - 2026-11-20

### Changed

- CI/CD v2.0: one local gate (`./task gate`, `./task gate-full`), one release mechanism
  (`./task release`, no push without `--push`), the golden contract job renamed to `preflight`
  and required by every expensive job, and a `VERSION` file that release owns.
- The vendored `ops/scripts/contract-check.sh` is refreshed to the single shared blob.
