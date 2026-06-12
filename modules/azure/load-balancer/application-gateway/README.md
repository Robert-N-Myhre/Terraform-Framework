# Azure Load Balancer — Application Gateway v2

Creates an Application Gateway (Standard_v2 or WAF_v2) with autoscaling, zone
deployment, Key Vault-sourced SSL certificates via managed identity, custom probes,
HTTP(S) listeners, and basic routing rules.

**Independently invocable.** The dedicated gateway subnet, WAF policy, and managed
identity are plain ID inputs.

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
| gateway_subnet_id | `string` | Dedicated subnet ID | n/a | yes |
| sku_name | `string` | Standard_v2 / WAF_v2 | `"Standard_v2"` | no |
| autoscale_min_capacity | `number` | Min capacity units | `1` | no |
| autoscale_max_capacity | `number` | Max capacity units | `4` | no |
| zones | `list(string)` | Availability zones | `[]` | no |
| waf_policy_id | `string` | WAF policy ID | `null` | no |
| backend_pools | `map(object)` | Pools (FQDNs/IPs) | n/a | yes |
| backend_http_settings | `map(object)` | Settings with optional probe ref | n/a | yes |
| probes | `map(object)` | Custom probes | `{}` | no |
| http_listeners | `map(object)` | Listeners (HTTPS needs cert key) | n/a | yes |
| ssl_certificates | `map(object)` | Key Vault secret IDs | `{}` | no |
| identity_ids | `list(string)` | User-assigned identities (Key Vault access) | `[]` | no |
| request_routing_rules | `map(object)` | Listener → pool + settings | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | Application gateway ID |
| lb_address | Frontend public IP |
| listener_ids | Logical name → inner listener name |
| backend_ids | Logical name → inner pool name |
| backend_address_pool_resource_ids | Logical name → full pool resource ID |

## Usage

```hcl
module "app_gateway" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/load-balancer/application-gateway"

  prefix      = "acme"
  environment = "prod"
  owner       = "web-team"
  cost_center = "CC-4100"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"
  gateway_subnet_id   = "/subscriptions/.../subnets/acme-azure-prod-snet-agw"
  zones               = ["1", "2", "3"]

  backend_pools = {
    web = { ip_addresses = ["10.40.10.10", "10.40.10.11"] }
  }

  backend_http_settings = {
    web = { port = 8080, probe_key = "web" }
  }

  probes = {
    web = { path = "/healthz" }
  }

  http_listeners = {
    http = { frontend_port = 80 }
  }

  request_routing_rules = {
    web = {
      priority                  = 100
      listener_key              = "http"
      backend_pool_key          = "web"
      backend_http_settings_key = "web"
    }
  }
}
```

## Cross-cloud divergence

One monolithic resource with name-correlated inner blocks — AWS ALB and GCP HTTP(S)
LB decompose the same concepts into separate resources. This module derives inner
names deterministically from logical keys, so renaming a key replaces the inner
block. v1 SKUs are deprecated and not supported.
