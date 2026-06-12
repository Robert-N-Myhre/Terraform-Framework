# GCP Firewall — VPC Firewall Rules

Creates classic (network-global, stateful) VPC firewall rules with tag or
service-account targeting, allow/deny actions, priorities, and optional logging.

**Independently invocable.** The network is supplied by name/self-link.

> Classic VPC firewall rules are **not labelable** — the governance tagging
> contract is honored via naming convention only in this module.

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
| owner | `string` | Convention parity (rules not labelable) | n/a | yes |
| cost_center | `string` | Convention parity | n/a | yes |
| additional_tags | `map(string)` | Convention parity | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| network_name | `string` | Target VPC name/self-link | n/a | yes |
| rules | `map(object)` | Rules with direction, action, priority, targeting, `allow_deny` protocol list | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → rule ID (== rule_ids; no grouping resource in GCP) |
| rule_ids | Logical name → rule ID |
| rule_self_links | Logical name → self-link |

## Usage

```hcl
module "firewall_rules" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/firewall/vpc-firewall-rules"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "cc-1042"

  project_id   = "acme-prod-networking"
  network_name = "acme-gcp-prod-vpc-01"

  rules = {
    allow-https-in = {
      direction     = "INGRESS"
      action        = "allow"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["web"]
      allow_deny    = [{ protocol = "tcp", ports = ["443"] }]
      log_enabled   = true
    }
    web-to-app = {
      direction   = "INGRESS"
      action      = "allow"
      source_tags = ["web"]
      target_tags = ["app"]
      allow_deny  = [{ protocol = "tcp", ports = ["8080"] }]
    }
  }
}
```

## Cross-cloud divergence

Rules are network-global and select workloads via **network tags** or service
accounts — no subnet/NIC association step (Azure) and no SG references (AWS).
`source_tags` → `target_tags` is the closest analogue to AWS SG-to-SG rules.
A rule cannot mix tags and service accounts. Every VPC has implied
allow-egress-all / deny-ingress-all rules at priority 65535.
