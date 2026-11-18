# Security policy

## Supported versions

The deployed site at qouver.com and the `main` branch are the only supported versions. Older commits
receive no fixes, and there is no long-term-support branch.

## Reporting a vulnerability

Do not open a public issue, pull request or discussion for a security problem. Use GitHub private
vulnerability reporting:

<https://github.com/nferdazel/qouver/security/advisories/new> (the repository's **Security** tab,
then **Report a vulnerability**). Advisory drafts stay private until they are published. That channel
is enabled on this repository.

If GitHub reporting is unavailable to you, write to `hello@qouver.com` with the same content and say
in the first line that it is a security report.

A useful report includes:

- the affected route, package or deploy script, and the commit you tested;
- what you did, what happened, and the impact you believe it has;
- the smallest reproduction, against your own instance or the public site, with no data that is not
  yours;
- any suggested fix.

Do not include real credentials, personal data, or a dump from a live system, and do not test against
the production host: firewall, systemd units, podman and Caddy on the VPS are the host owner's, not
this repository's.

## Scope

In scope:

- the HTTP surface of `apps/api` (`/api/*`, `/healthz`) and its handlers;
- the contract in `packages/contracts` and the generated client in `packages/api-client`;
- the static site in `apps/web`, including anything that ships to the browser;
- `ops/scripts/` and `deploy/`, as written in this repository;
- anything here that would expose a credential, a token or private content.

Out of scope:

- the host itself: firewall, podman, systemd, Caddy binary, TLS configuration;
- third-party services (Cloudflare, the VPS provider);
- missing hardening headers that no browser of record flags.

## What happens next

The repository has a single maintainer. Reports are acknowledged and investigated as capacity allows;
there is no formal response deadline and no bug bounty. Accepted reports are fixed privately and
published in the advisory so you can update before details become public.

## Handling

Fixes go out with the normal deploy on `main`, after the gate in `./task ci` is green. The advisory
names the commit that carries the fix.
