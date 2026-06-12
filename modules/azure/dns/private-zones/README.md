# Azure DNS — Private DNS Zones

Creates private DNS zones with virtual network links (optional VM auto-registration)
and A/CNAME/TXT record sets.

**Independently invocable.** VNet IDs are plain inputs; no framework dependency
exists. Also fits `privatelink.*` zones used by Private Endpoints.

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
| private_zones | `map(object)` | Zones with `vnet_links`, `a_records`, `cname_records`, `txt_records` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| zone_ids | Logical name → zone ID |
| zone_names | Logical name → domain name |
| vnet_link_ids | `<zone>/<link>` → link ID |
| record_ids | `<type>/<zone>/<record>` → record ID |

## Usage

```hcl
module "private_dns" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/dns/private-zones"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "CC-3300"

  resource_group_name = "rg-acme-prod-network"

  private_zones = {
    internal = {
      domain_name = "prod.internal.example.com"
      vnet_links = {
        hub = { vnet_id = "/subscriptions/.../virtualNetworks/acme-azure-prod-vnet-01" }
      }
      a_records = {
        api = { name = "api", records = ["10.40.10.15"] }
      }
    }
  }
}
```

## Cross-cloud divergence

Azure zones can exist with zero links (resolution requires a link); AWS private
zones require ≥1 VPC at creation. `registration_enabled` auto-registers VM records —
AWS/GCP/OCI have no direct equivalent. Only one registration-enabled link is allowed
per VNet.
