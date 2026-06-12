# Azure Core Network

Creates a virtual network with standalone subnets (service endpoints, delegations),
per-subnet route tables with UDRs, an optional NAT gateway, optional Network Watcher
flow logs, and a CanNotDelete management lock on the VNet (on by default).

**Independently invocable.** The resource group must already exist — its lifecycle
belongs to the consumer. NSG association is intentionally not handled here; invoke
`azure/firewall/nsgs` independently.

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
| address_space | `list(string)` | VNet address space(s) | n/a | yes |
| dns_servers | `list(string)` | Custom DNS (empty = Azure DNS) | `[]` | no |
| subnets | `map(object)` | Subnets with optional delegation, service endpoints, UDRs | n/a | yes |
| nat_gateway_subnet_keys | `list(string)` | Subnet keys egressing via NAT gateway | `[]` | no |
| nat_gateway_zones | `list(string)` | Zones for NAT public IP (zonal) | `[]` | no |
| enable_flow_logs | `bool` | Network Watcher flow logs | `false` | no |
| network_watcher_name | `string` | Existing Network Watcher name | `null` | conditional |
| network_watcher_resource_group | `string` | Network Watcher RG | `null` | conditional |
| flow_log_storage_account_id | `string` | Storage account for flow logs | `null` | conditional |
| flow_log_retention_days | `number` | Flow log retention | `30` | no |
| enable_management_lock | `bool` | CanNotDelete lock on VNet | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VNet ID |
| network_name | VNet name (for peering/DNS links) |
| network_cidr | VNet address space (list) |
| subnet_ids | Logical name → subnet ID |
| subnet_cidrs | Logical name → address prefixes |
| route_table_ids | Logical name → route table ID |
| nat_ids | `{ natgw = <id> }` or empty |
| nat_public_ips | `{ natgw = <ip> }` or empty |
| flow_log_id | Flow log ID or null |

## Usage

```hcl
module "core_network" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/core-network"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"
  address_space       = ["10.40.0.0/16"]

  subnets = {
    app = {
      address_prefixes = ["10.40.10.0/24"]
      routes = {
        to-firewall = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.40.250.4"
        }
      }
    }
    data = { address_prefixes = ["10.40.20.0/24"] }
  }

  nat_gateway_subnet_keys = ["app"]
}
```

## Cross-cloud divergence

- Subnets are **standalone resources** here; never mix with inline `subnet` blocks
  on the VNet or Terraform will fight itself on every plan.
- Azure has no internet gateway: outbound is default (or NAT GW / firewall), and
  route tables attach via a separate association resource per subnet.
- `AzureBastionSubnet`, `GatewaySubnet`, and `AzureFirewallSubnet` are reserved
  names with sizing rules — create them through `subnets` with the exact name when
  needed by separately invoked modules.

## Destroy note

`enable_management_lock` defaults to `true`. Apply with it set to `false` before
destroying the VNet.
