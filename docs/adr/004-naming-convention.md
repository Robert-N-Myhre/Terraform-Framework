# ADR 004 — Naming Convention

**Status:** Accepted
**Date:** 2026-06-11

## Context

Multi-cloud estates accumulate resources whose origin, environment, and owner
are invisible from the name alone. Console-side debugging, billing exports,
SIEM events, and tickets all surface *names* first. We need names that are
self-identifying across four clouds while respecting each cloud's character
rules — and we need them without a shared naming module (ADR 001/003).

## Decision

Every resource name derives, via per-module locals, from:

```
{prefix}-{cloud}-{environment}-{resource-type}-{suffix}
```

### Token definitions

| Token | Source | Notes |
|-------|--------|-------|
| `prefix` | `var.prefix` | Org/project identifier; keep short (2-8 lowercase chars) — some resources (AWS ELB) cap total length at 32. |
| `cloud` | constant per module | `aws` / `azure` / `gcp` / `oci`. Disambiguates names in cross-cloud inventories and exports. |
| `environment` | `var.environment` | Identical value to the mandatory tag — names and tags can never disagree. |
| `resource-type` | constant per resource | Short lowercase token (`vpc`, `nsg`, `tgw`, `drg`, ...). Token table lives in `governance/naming/README.md`. |
| `suffix` | `var.name_suffix` (default `"01"`) | Instance disambiguator; lets the same module be invoked multiple times in one environment. For `for_each` resources the logical map key takes this position. |

Implemented in every module as:

```hcl
locals {
  name_base = "${var.prefix}-<cloud>-${var.environment}"
}
# usage: "${local.name_base}-vpc-${var.name_suffix}"
```

**No hardcoded names anywhere** — every name flows through the pattern.

### Sanctioned deviations

- **Cloud-mandated names** override the convention: Azure's `GatewaySubnet`,
  `AzureFirewallSubnet`, `AzureBastionSubnet` must be exact; OCI DNS labels and
  GCP zone resource names have their own grammars. Modules document each case.
- **Explicit override variables** exist only where external systems commonly
  dictate names (e.g., `dx_gateway_name`). Default remains convention-derived
  (`null` → pattern).
- **Keyed resources** (subnets, rules, listeners) substitute the logical map
  key for `suffix`, keeping plan addresses and names aligned.

## Rationale for this token order

Most-significant to least-significant reads naturally in sorted lists: all of
one org's resources group first, then by cloud, then environment — exactly the
hierarchy used when scanning a billing export or inventory. `resource-type`
before `suffix` keeps same-type resources adjacent.

## Consequences

- Names are predictable enough to be *guessed* during incident response.
- Lowercase-and-hyphen output is automatically valid for GCP's strict grammar
  and acceptable everywhere else used by this framework.
- The convention consumes name length; consumers with long prefixes and AWS
  load balancers must budget characters (documented in module READMEs).
- Renaming tokens forces resource replacement on most clouds — `prefix`,
  `environment`, and `name_suffix` should be treated as immutable per
  deployment.
