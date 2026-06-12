# Azure Transit — VNet Peering

Creates bidirectional VNet peering (two one-way resources per pair) with gateway
transit and forwarded-traffic options.

**Independently invocable.** VNet names and IDs are plain inputs. Cross-subscription
peering works when the configured provider identity has RBAC on both sides;
cross-tenant peering needs provider aliases in the consumer root (out of scope).

> Azure VNet peerings are **not taggable** — the governance tagging contract is
> honored via naming convention only in this module.

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
| owner | `string` | Convention parity (not applied — peerings untaggable) | n/a | yes |
| cost_center | `string` | Convention parity (not applied) | n/a | yes |
| additional_tags | `map(string)` | Convention parity (not applied) | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| peerings | `map(object)` | Pairs with per-direction `allow_forwarded_traffic`, `allow_gateway_transit`, `use_remote_gateways` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connection_ids | `<peering>/a-to-b` and `<peering>/b-to-a` → peering ID |

## Usage

```hcl
module "peering" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/transit/peering"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  peerings = {
    hub-spoke1 = {
      vnet_a_name                = "acme-azure-prod-vnet-hub"
      vnet_a_resource_group_name = "rg-acme-prod-hub"
      vnet_a_id                  = "/subscriptions/.../virtualNetworks/acme-azure-prod-vnet-hub"
      vnet_b_name                = "acme-azure-prod-vnet-spoke1"
      vnet_b_resource_group_name = "rg-acme-prod-spoke1"
      vnet_b_id                  = "/subscriptions/.../virtualNetworks/acme-azure-prod-vnet-spoke1"

      a_to_b = { allow_gateway_transit = true, allow_forwarded_traffic = true }
      b_to_a = { use_remote_gateways = true }
    }
  }
}
```

## Cross-cloud divergence

Two one-way resources vs AWS's single handshake resource, GCP's symmetric config,
and OCI's LPG pairs. `allow_gateway_transit` (hub) pairs with `use_remote_gateways`
(spoke) — never both on one side; the spoke flag also requires a gateway to already
exist in the hub. Peering is non-transitive on every cloud.
