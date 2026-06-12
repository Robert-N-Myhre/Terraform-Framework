# Azure Load Balancer — Standard Load Balancer

Creates a Standard SKU L4 load balancer (public or internal frontend), backend
address pools, health probes, load-balancing rules, and explicit outbound SNAT
rules. Backend pool membership is the consumer's responsibility (NIC association or
address-based).

**Independently invocable.** Subnet IDs are plain inputs.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.80 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (mandatory tag) | n/a | yes |
| cost_center | `string` | Cost center (mandatory tag) | n/a | yes |
| additional_tags | `map(string)` | Extra tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| resource_group_name | `string` | Existing resource group | n/a | yes |
| location | `string` | Azure region | n/a | yes |
| frontend_type | `string` | `public` / `internal` | `"internal"` | no |
| subnet_id | `string` | Internal frontend subnet | `null` | conditional |
| private_ip_address | `string` | Static internal IP (null = dynamic) | `null` | no |
| zones | `list(string)` | Zone redundancy | `[]` | no |
| backend_pools | `set(string)` | Pool logical names | n/a | yes |
| health_probes | `map(object)` | Probes | `{}` | no |
| rules | `map(object)` | LB rules (SNAT disabled by default) | `{}` | no |
| outbound_rules | `map(object)` | Explicit outbound SNAT (public only) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | Load balancer ID |
| lb_address | Public or private frontend IP |
| listener_ids | Logical rule name → rule ID |
| backend_ids | Logical pool name → pool ID |
| probe_ids | Logical probe name → probe ID |

## Usage

```hcl
module "internal_lb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/load-balancer/load-balancer"

  prefix      = "acme"
  environment = "prod"
  owner       = "data-team"
  cost_center = "CC-4200"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"
  frontend_type       = "internal"
  subnet_id           = "/subscriptions/.../subnets/acme-azure-prod-snet-data"
  private_ip_address  = "10.40.20.100"
  zones               = ["1", "2", "3"]

  backend_pools = ["sql"]

  health_probes = {
    sql = { port = 1433 }
  }

  rules = {
    sql = {
      frontend_port    = 1433
      backend_port     = 1433
      backend_pool_key = "sql"
      probe_key        = "sql"
    }
  }
}
```

## Cross-cloud divergence

Backend pools are joined **from the NIC side** (or address-based) — opposite
direction from AWS target-group registration. `disable_outbound_snat` defaults to
`true` here: pair public LBs with explicit `outbound_rules` instead of implicit
SNAT. Basic SKU is deliberately not supported (retired Sept 2025).
