# Security Policy

## Reporting a vulnerability

Please report security issues **privately** — do not open a public issue for
anything exploitable.

The preferred channel is GitHub's private vulnerability reporting: go to the
**Security** tab of this repository and click **Report a vulnerability**. (If
that option isn't visible, the maintainer can enable it under
Settings → Advanced Security → Private vulnerability reporting.)

Please include:

- The module(s) affected (e.g., `modules/aws/firewall/security-groups`)
- A description of the issue and its security impact
- A minimal configuration or steps that reproduce it

This is a personal reference framework maintained on a best-effort basis. You
can expect an acknowledgement within a reasonable time and fixes prioritized by
severity; there is no formal SLA.

## Scope

This repository contains **Terraform module definitions, not running
infrastructure**. The most relevant classes of issue are:

- **Insecure defaults** — a module default that exposes a resource (an
  over-broad ingress rule, a disabled deletion lock, public exposure where
  private is expected).
- **Governance gaps** — a path that bypasses the tagging, naming, or
  deletion-protection conventions in a way that weakens security posture.
- **Misleading documentation** — examples or READMEs that steer a consumer
  toward an insecure deployment.

The consumer remains responsible for their own state backend, credentials, and
the security of resources they deploy with these modules. **State files may
contain sensitive values** (VPN pre-shared keys, BGP auth keys, certificate
private keys) — see [docs/state-management.md](docs/state-management.md).

## Supported versions

The latest commit on `main` is the supported version. Fixes are applied
forward; older tags are not back-patched.
