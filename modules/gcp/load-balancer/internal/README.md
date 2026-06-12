# GCP Load Balancer — Internal Passthrough Network LB

Creates an internal L4 passthrough load balancer: regional health check, region
backend service (INTERNAL scheme), and forwarding rule with optional static IP,
all-ports mode, and global access.

**Independently invocable.** Network/subnet self-links and backend instance
groups/NEGs are plain inputs — group lifecycle (MIGs/NEGs) belongs to the consumer.

> Health checks come from GCP's central ranges `35.191.0.0/16` and
> `130.211.0.0/22` — allow them in your firewall rules
> (`gcp/firewall/vpc-firewall-rules`).

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
| owner | `string` | Owning team (label) | n/a | yes |
| cost_center | `string` | Cost center (label) | n/a | yes |
| additional_tags | `map(string)` | Extra labels | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| region | `string` | LB region | n/a | yes |
| network_self_link | `string` | VPC self-link | n/a | yes |
| subnet_self_link | `string` | Frontend subnet | n/a | yes |
| ip_address | `string` | Static IP (null = ephemeral) | `null` | no |
| protocol | `string` | TCP / UDP | `"TCP"` | no |
| ports | `list(string)` | Up to 5 ports | `[]` | no |
| all_ports | `bool` | Forward all ports | `false` | no |
| allow_global_access | `bool` | Cross-region clients | `false` | no |
| backend_groups | `map(object)` | Instance groups / NEGs | n/a | yes |
| health_check | `object` | TCP/HTTP/HTTPS check | n/a | yes |
| session_affinity | `string` | NONE / CLIENT_IP variants | `"NONE"` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | Forwarding rule ID |
| lb_address | Internal IP |
| listener_ids | `{ forwarding_rule = <self-link> }` |
| backend_ids | `{ backend_service = <id> }` |
| health_check_id | Health check ID |

## Usage

```hcl
module "internal_lb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/load-balancer/internal"

  prefix      = "acme"
  environment = "prod"
  owner       = "data-team"
  cost_center = "cc-4200"

  project_id        = "acme-prod-networking"
  region            = "us-east1"
  network_self_link = "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/global/networks/acme-gcp-prod-vpc-01"
  subnet_self_link  = "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/regions/us-east1/subnetworks/acme-gcp-prod-subnet-data"
  ip_address        = "10.60.20.100"

  ports = ["5432"]

  backend_groups = {
    primary = { group = "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/zones/us-east1-b/instanceGroups/db-mig" }
  }

  health_check = { port = 5432 }
}
```

## Cross-cloud divergence

Passthrough — backends see the **original client IP** (like AWS NLB with client-IP
preservation; Azure LB DNATs instead). No TLS termination at L4 (AWS NLB uniquely
offers TLS listeners). The "LB" is just health check → backend service → forwarding
rule; there is no appliance resource.
