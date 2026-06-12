# Governance — Tagging Strategy

> **This directory is documentation and a reference implementation only.**
> It is **not** a callable Terraform module, and no leaf module may `source` it.
> Each leaf module carries its own self-contained copy of the tagging locals
> pattern below. See [ADR 003](../../docs/adr/003-tagging-as-locals.md) for the
> rationale.

## The pattern

Every leaf module in this framework defines this locals block (with
`module_source` set to its own path) and applies `local.all_tags` to every
taggable resource. No inline tag blocks are permitted anywhere.

```hcl
locals {
  mandatory_tags = {
    environment   = var.environment
    owner         = var.owner
    cost_center   = var.cost_center
    managed_by    = "terraform"
    module_source = "<module-path-relative-to-repo-root>"
  }
  all_tags = merge(var.additional_tags, local.mandatory_tags)
}
```

The merge order is deliberate: `additional_tags` first, `mandatory_tags` second —
**mandatory tags win on key collision**. A consumer cannot override `managed_by`
or misreport `cost_center` by passing a colliding key.

## Mandatory tag definitions

| Tag | Source | Definition | Example |
|-----|--------|------------|---------|
| `environment` | `var.environment` | Deployment environment. Allowed values are an organizational decision; this framework recommends `dev`, `test`, `stage`, `prod`. | `prod` |
| `owner` | `var.owner` | The team (preferred) or individual accountable for the resource. Used for escalation and review. | `network-team` |
| `cost_center` | `var.cost_center` | The chargeback/showback code the spend lands on. | `CC-1042` |
| `managed_by` | constant | Always `terraform`. Signals that manual console changes will be reverted by the next apply. | `terraform` |
| `module_source` | constant per module | Repo-relative path of the module that created the resource. Answers "which code do I edit?" during incident response. | `modules/aws/core-network` |

## Required input variables

Every module exposes exactly these governance inputs:

```hcl
variable "environment"     { type = string }              # required
variable "owner"           { type = string }              # required
variable "cost_center"     { type = string }              # required
variable "additional_tags" { type = map(string), default = {} }
```

`additional_tags` is the extension point: teams add `application`, `data_class`,
`compliance_scope`, etc. without any module change.

## Per-cloud mechanics

The *schema* is identical on all four clouds; the *mechanism* differs:

| Cloud | Mechanism | Caveats |
|-------|-----------|---------|
| AWS | `tags` argument | `Name` tag is added per resource on top of `all_tags`. |
| Azure | `tags` argument | VNet **peerings are not taggable** — naming convention carries governance there. |
| GCP | `labels` argument | Keys/values must be **lowercase** (`[a-z0-9_-]`); modules lowercase all values, and `module_source` uses `-` instead of `/`. Several resources (classic firewall rules, DNS policies, security policies, peerings) are not labelable. |
| OCI | `freeform_tags` argument | For enforced (schema-validated) tagging, migrate to **defined tags** with a tag namespace — see Enforcement below. |

Where a resource type supports no tags at all, the module README says so
explicitly and the naming convention is the governance carrier.

## Enforcement

Self-contained locals give consistency by convention. To make the schema
*enforced*, layer policy on top — without changing any module:

- **AWS**: Tag Policies (Organizations) + `aws:RequestTag` IAM conditions.
- **Azure**: Azure Policy `Require a tag on resources` / `Inherit a tag`.
- **GCP**: Organization Policy custom constraints on labels.
- **OCI**: Tag defaults on compartments + IAM policy requiring defined tags.

## Auditing

Each cloud's native query surface can report on the mandatory keys:
AWS Resource Groups / Tag Editor, Azure Resource Graph, GCP Asset Inventory,
OCI Search. The constant `managed_by = "terraform"` cleanly separates
IaC-managed estate from hand-built resources in those queries.
