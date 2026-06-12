# Azure Firewall — Managed Appliance

Creates an Azure Firewall (Standard or Premium) with a firewall policy, one rule
collection group carrying network/application/DNAT collections, a Standard public
IP, optional zone deployment, and a CanNotDelete management lock (on by default).

**Independently invocable.** Requires an existing subnet named exactly
`AzureFirewallSubnet` (minimum /26), supplied by ID. Steering traffic to the
firewall is the consumer's job: add UDRs with `next_hop_type = "VirtualAppliance"`
and the `firewall_private_ip` output.

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
| firewall_subnet_id | `string` | AzureFirewallSubnet ID (/26 min) | n/a | yes |
| sku_tier | `string` | Standard / Premium | `"Standard"` | no |
| zones | `list(string)` | Availability zones | `[]` | no |
| threat_intelligence_mode | `string` | Off / Alert / Deny | `"Alert"` | no |
| dns_proxy_enabled | `bool` | DNS proxy (needed for FQDN network rules) | `false` | no |
| dns_servers | `list(string)` | Custom DNS for the policy | `[]` | no |
| network_rule_collections | `map(object)` | L3/L4 collections | `{}` | no |
| application_rule_collections | `map(object)` | L7 FQDN collections | `{}` | no |
| nat_rule_collections | `map(object)` | DNAT collections | `{}` | no |
| enable_management_lock | `bool` | CanNotDelete lock | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | `{ firewall = <id> }` |
| firewall_private_ip | UDR next-hop IP |
| firewall_public_ip | DNAT/public IP |
| policy_id | Firewall policy ID |
| rule_ids | `{ rule_collection_group = <id> }` |

## Usage

```hcl
module "azure_firewall" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/firewall/azure-firewall"

  prefix      = "acme"
  environment = "prod"
  owner       = "security-team"
  cost_center = "CC-2001"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"
  firewall_subnet_id  = "/subscriptions/.../subnets/AzureFirewallSubnet"
  zones               = ["1", "2", "3"]

  network_rule_collections = {
    egress-allow = {
      priority = 200
      action   = "Allow"
      rules = {
        https-out = {
          protocols             = ["TCP"]
          source_addresses      = ["10.40.0.0/16"]
          destination_addresses = ["*"]
          destination_ports     = ["443"]
        }
      }
    }
  }
}
```

## Cross-cloud divergence

Azure Firewall receives traffic via UDRs to its private IP; AWS Network Firewall
inserts routable VPC endpoints; GCP Cloud NGFW attaches policies without an
appliance hop; OCI Network Firewall is Palo Alto-backed. This module uses the
firewall-policy rule model exclusively — the classic inline-rules model is
deprecated.

## Destroy note

`enable_management_lock` defaults to `true`. Apply with it set to `false` before
destroying.
