# Azure DNS — DNS Private Resolver

Creates a DNS Private Resolver with inbound endpoints (on-prem → Azure resolution),
outbound endpoints, forwarding rulesets with per-domain rules, and ruleset VNet
links.

**Independently invocable.** VNet and delegated-subnet IDs are plain inputs. Each
endpoint requires a dedicated subnet delegated to `Microsoft.Network/dnsResolvers`
(create via `azure/core-network`'s `delegation` option or any other means).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80 (resolver resources need ≥ 3.40) |

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
| location | `string` | Azure region (= VNet region) | n/a | yes |
| vnet_id | `string` | Resolver's VNet | n/a | yes |
| inbound_endpoints | `map(object)` | `{ subnet_id }` per endpoint | `{}` | no |
| outbound_endpoints | `map(object)` | `{ subnet_id }` per endpoint | `{}` | no |
| forwarding_rulesets | `map(object)` | Rulesets: endpoints, rules (domains need trailing dot), VNet links | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| resolver_id | Resolver ID |
| inbound_endpoint_ids | Logical name → endpoint ID |
| inbound_endpoint_ips | Logical name → private IP (on-prem forwarder target) |
| outbound_endpoint_id | Logical name → endpoint ID |
| ruleset_ids | Logical name → ruleset ID |
| rule_ids | `<ruleset>/<rule>` → rule ID |

## Usage

```hcl
module "dns_resolver" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/dns/resolver"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "CC-3300"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"
  vnet_id             = "/subscriptions/.../virtualNetworks/acme-azure-prod-vnet-01"

  inbound_endpoints  = { main = { subnet_id = "/subscriptions/.../subnets/snet-dnspr-in" } }
  outbound_endpoints = { main = { subnet_id = "/subscriptions/.../subnets/snet-dnspr-out" } }

  forwarding_rulesets = {
    corp = {
      outbound_endpoint_keys = ["main"]
      vnet_link_ids          = ["/subscriptions/.../virtualNetworks/acme-azure-prod-vnet-01"]
      rules = {
        corp-domain = {
          domain_name        = "corp.example.com."
          target_dns_servers = [{ ip_address = "10.250.0.10" }]
        }
      }
    }
  }
}
```

## Cross-cloud divergence

Mirrors AWS Route 53 Resolver's endpoint split, but rules group into **rulesets**
that link to VNets (AWS associates individual rules with VPCs). Domain names in
rules require a **trailing dot** — the most common apply-time error with this
service.
