# GCP Core Network

Creates a custom-mode global VPC with regional subnets (secondary ranges for GKE,
per-subnet flow logs, Private Google Access), static routes, and optional Cloud NAT
(router + NAT).

**Independently invocable.** Only a project ID is required.

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
| owner | `string` | Owning team (mandatory label, lowercased) | n/a | yes |
| cost_center | `string` | Cost center (mandatory label, lowercased) | n/a | yes |
| additional_tags | `map(string)` | Extra labels (lowercased) | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| routing_mode | `string` | REGIONAL / GLOBAL | `"GLOBAL"` | no |
| delete_default_routes_on_create | `bool` | Strict egress posture | `false` | no |
| subnets | `map(object)` | Regional subnets with secondary ranges + flow logs | n/a | yes |
| static_routes | `map(object)` | Routes (one next_hop_* each) | `{}` | no |
| cloud_nat | `object` | Cloud Router + NAT config | `{ enabled = false }` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id / network_name / network_self_link | VPC identifiers |
| network_cidr | Always `null` (GCP has no network-level CIDR) — contract parity |
| subnet_ids / subnet_self_links / subnet_cidrs | Per-subnet identifiers |
| route_ids | Logical name → route ID (no route tables in GCP) |
| nat_ids | `{ nat = <id> }` or empty |
| flow_log_id | Always `null` — flow logs are subnet settings |

## Usage

```hcl
module "core_network" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/core-network"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "cc-1042"

  project_id = "acme-prod-networking"

  subnets = {
    app-east = {
      ip_cidr_range = "10.60.10.0/24"
      region        = "us-east1"
      flow_logs     = { enabled = true }
      secondary_ip_ranges = {
        pods     = "10.61.0.0/16"
        services = "10.62.0.0/20"
      }
    }
  }

  cloud_nat = { enabled = true, region = "us-east1" }
}
```

## Cross-cloud divergence

- The VPC is **global**; subnets are **regional**. There is no IGW resource — the
  implicit `default-internet-gateway` is referenced by routes.
- There are **no route tables**: routes attach to the network and select instances
  by network tag.
- Flow logs are **per-subnet settings**, not standalone resources — hence the
  null `flow_log_id` parity output.
- Labels (metadata) ≠ network tags (firewall targeting). This module manages
  labels; firewall modules consume network tags.
