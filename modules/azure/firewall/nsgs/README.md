# Azure Firewall — Network Security Groups

Creates NSGs with prioritized allow/deny rules (CIDRs, service tags, or ASG
references) and optional subnet associations.

**Independently invocable.** Subnet IDs and ASG IDs are plain inputs. Pair with
`azure/firewall/asgs` (invoked independently) when rules should target application
security groups.

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
| network_security_groups | `map(object)` | NSGs with `rules` map and optional `subnet_ids` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → NSG ID |
| firewall_names | Logical name → NSG name |
| rule_ids | `<nsg>/<rule>` → rule ID |
| subnet_association_ids | `<nsg>/<subnet-id>` → association ID |

## Usage

```hcl
module "nsgs" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/firewall/nsgs"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"

  network_security_groups = {
    app = {
      subnet_ids = ["/subscriptions/.../subnets/acme-azure-prod-snet-app"]
      rules = {
        allow-https-in = {
          priority                     = 100
          direction                    = "Inbound"
          access                       = "Allow"
          protocol                     = "Tcp"
          destination_port_ranges      = ["443"]
          source_address_prefixes      = ["Internet"]
          destination_address_prefixes = ["10.40.10.0/24"]
        }
        deny-all-in = {
          priority  = 4096
          direction = "Inbound"
          access    = "Deny"
          protocol  = "*"
        }
      }
    }
  }
}
```

## Cross-cloud divergence

NSGs are stateful, subnet/NIC-associated, and support **Deny** rules and service
tags — AWS SGs are allow-only and ENI-attached; GCP rules are network-global and
tag-targeted. Where AWS uses SG-to-SG references, Azure uses ASG references
(`source/destination_application_security_group_ids`).
