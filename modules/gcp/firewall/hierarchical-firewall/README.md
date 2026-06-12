# GCP Firewall — Hierarchical Firewall Policy

Creates an organization/folder-level firewall policy with prioritized rules
(allow/deny/goto_next) and associations to org or folder nodes. Rules cascade to
every project beneath the attached node and evaluate **before** VPC-level rules.

**Independently invocable.** Requires org-level IAM
(`roles/compute.orgSecurityResourceAdmin`) — project credentials alone cannot apply
this module.

> Hierarchical firewall policies are **not labelable** — governance tagging is
> honored via naming convention only.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Convention parity | n/a | yes |
| cost_center | `string` | Convention parity | n/a | yes |
| additional_tags | `map(string)` | Convention parity | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| parent_node | `string` | `organizations/<id>` or `folders/<id>` | n/a | yes |
| policy_description | `string` | Policy description | `"Managed by Terraform"` | no |
| rules | `map(object)` | Rules: priority, direction, allow/deny/goto_next, layer4_configs | n/a | yes |
| associations | `map(string)` | Logical name → enforced node | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | `{ policy = <id> }` |
| rule_ids | Logical name → rule priority |
| association_ids | Logical name → association ID |

## Usage

```hcl
module "hierarchical_firewall" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/firewall/hierarchical-firewall"

  prefix      = "acme"
  environment = "prod"
  owner       = "security-team"
  cost_center = "cc-2001"

  parent_node = "organizations/123456789012"

  rules = {
    block-known-bad = {
      priority       = 100
      direction      = "INGRESS"
      action         = "deny"
      src_ip_ranges  = ["198.51.100.0/24"]
      layer4_configs = [{ ip_protocol = "all" }]
      enable_logging = true
    }
    delegate-rest = {
      priority       = 65000
      direction      = "INGRESS"
      action         = "goto_next"
      src_ip_ranges  = ["0.0.0.0/0"]
      layer4_configs = [{ ip_protocol = "all" }]
    }
  }

  associations = {
    prod-folder = "folders/345678901234"
  }
}
```

## Cross-cloud divergence

Evaluates before project VPC rules and cascades organization-wide — no true
AWS/OCI/Azure data-plane equivalent. `goto_next` delegates decisions to lower
levels. Rules target **service accounts only** (network tags are not supported at
this level).
