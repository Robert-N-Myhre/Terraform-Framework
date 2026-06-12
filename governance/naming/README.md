# Governance — Naming Convention

> **This directory is documentation only.** It is not a callable Terraform
> module, and no leaf module may `source` it. Each leaf module derives all
> resource names from its own naming locals. See
> [ADR 004](../../docs/adr/004-naming-convention.md) for the rationale.

## The pattern

```
{prefix}-{cloud}-{environment}-{resource-type}-{suffix}
```

Implemented in every module as:

```hcl
locals {
  name_base = "${var.prefix}-<cloud>-${var.environment}"
  # e.g. resource name: "${local.name_base}-vpc-${var.name_suffix}"
}
```

No resource name is ever hardcoded — every name derives from this pattern via
locals.

## Token definitions

| Token | Source | Definition | Example |
|-------|--------|------------|---------|
| `prefix` | `var.prefix` | Short org/project identifier (2-8 lowercase chars recommended). | `acme` |
| `cloud` | constant per module | `aws`, `azure`, `gcp`, or `oci`. Makes names self-identifying in multi-cloud inventories, exports, and tickets. | `aws` |
| `environment` | `var.environment` | Same value as the mandatory tag — names and tags never disagree. | `prod` |
| `resource-type` | constant per resource | Short type token chosen by the module (see table below). | `vpc` |
| `suffix` | `var.name_suffix` | Instance disambiguator, default `"01"`. Lets one consumer invoke the same module twice (`hub`, `01`, `02`). For keyed (for_each) resources, the logical map key takes this position (e.g. subnet names). | `01` |

## Resource-type tokens (representative)

| Token | Meaning | Token | Meaning |
|-------|---------|-------|---------|
| `vpc` / `vnet` / `vcn` | Network | `subnet` / `snet` | Subnet |
| `rt` | Route table | `igw` / `natgw` / `sgw` | Gateways |
| `sg` / `nsg` / `asg` | Security groups | `nacl` / `seclist` | Subnet ACLs |
| `nfw` / `fw` | Network firewall | `armor` / `hfwpolicy` | Edge / hierarchical policy |
| `zone` / `dnsview` | DNS zone / view | `rslvr` / `dnspr` | Resolver |
| `tgw` / `vwan` / `ncchub` / `drg` | Transit hub | `pcx` / `peer` / `lpg` | Peering |
| `vpngw` / `havpngw` / `vgw` | VPN gateway | `cgw` / `lngw` / `cpe` | Customer gateway |
| `dxgw` / `erc` / `icatt` / `vc` | Dedicated circuit | `alb` / `nlb` / `lb` / `agw` | Load balancer |
| `tg` / `bepool` / `bes` | Backend pool | `pip` / `eip` / `ip` | Public IP |

Modules may introduce additional tokens; they must be lowercase, short, and
documented in the module README via the resource names that appear there.

## Cloud-specific constraints the convention already absorbs

- **GCP**: names must match `[a-z]([-a-z0-9]*[a-z0-9])?` — the pattern is
  already lowercase-and-hyphens; keep `prefix`/`environment`/`name_suffix`
  lowercase.
- **Azure**: some resources reject hyphens (storage accounts) — not used by
  this framework's modules. Reserved subnet names (`GatewaySubnet`,
  `AzureFirewallSubnet`, `AzureBastionSubnet`) intentionally **break** the
  convention because Azure requires exact names; modules call this out.
- **AWS**: ALB/NLB names cap at 32 chars — keep `prefix` short in environments
  with long suffixes.
- **OCI**: `display_name` is mutable and non-unique; the convention is the only
  thing keeping names meaningful — don't edit display names in the console.

## Override guidance

The convention is a default, not a cage:

- `name_suffix` is the supported variation point for multiple instances.
- A handful of modules expose explicit name overrides where an externally
  mandated name is common (e.g., `dx_gateway_name`, `static_ip_name`). Use them
  only when an external system dictates the name, and record why in the
  consumer's code review.
- Never fork a module to change naming — if a new override is genuinely
  needed, add an optional variable upstream.
