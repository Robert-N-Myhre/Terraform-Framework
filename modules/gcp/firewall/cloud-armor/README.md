# GCP Firewall — Cloud Armor

Creates a Cloud Armor security policy with IP-range and CEL/preconfigured-WAF rules
(SQLi/XSS/etc), rate limiting and throttling, preview (log-only) mode, optional
Adaptive Protection, and a configurable default rule.

**Independently invocable.** Attachment to backend services happens by ID where the
load balancer is managed (e.g., `gcp/load-balancer/external` accepts
`security_policy_id`).

> Cloud Armor policies are **not labelable** — governance tagging is honored via
> naming convention only.

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
| project_id | `string` | GCP project ID | n/a | yes |
| default_action | `string` | Catch-all action | `"allow"` | no |
| rules | `map(object)` | IP or CEL rules, rate limits, preview | n/a | yes |
| adaptive_protection_enabled | `bool` | ML L7 DDoS defense | `false` | no |
| json_parsing | `string` | DISABLED / STANDARD | `"DISABLED"` | no |
| log_level | `string` | NORMAL / VERBOSE | `"NORMAL"` | no |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | `{ policy = <id> }` |
| policy_self_link | Self-link for backend service attachment |
| rule_ids | Logical name → rule priority |

## Usage

```hcl
module "cloud_armor" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/firewall/cloud-armor"

  prefix      = "acme"
  environment = "prod"
  owner       = "security-team"
  cost_center = "cc-2001"

  project_id     = "acme-prod-networking"
  default_action = "deny(403)"

  rules = {
    allow-corp = {
      priority      = 100
      action        = "allow"
      src_ip_ranges = ["203.0.113.0/24"]
    }
    block-sqli = {
      priority   = 200
      action     = "deny(403)"
      expression = "evaluatePreconfiguredWaf('sqli-v33-stable')"
      preview    = true
    }
    rate-limit = {
      priority      = 300
      action        = "throttle"
      src_ip_ranges = ["*"]
      rate_limit = {
        count_per_interval = 100
        interval_sec       = 60
      }
    }
  }
}
```

## Cross-cloud divergence

Edge WAF analogue of AWS WAF and Azure WAF; OCI WAF uses a different policy
document. CEL expressions and preconfigured rule names (`sqli-v33-stable`, ...) are
GCP-specific. Use `preview = true` to stage rules in log-only mode before
enforcement.
