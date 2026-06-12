# Azure Hybrid Connectivity — ExpressRoute

Creates an ExpressRoute circuit, optional Azure private peering (dual /30 BGP
sessions), an optional ExpressRoute gateway in one of two modes, and the
gateway-to-circuit connection (gated until the provider provisions the circuit).
CanNotDelete lock on the circuit by default.

- **`attachment_type = "vnet"`** (default) — classic ER virtual network gateway in
  a `GatewaySubnet`, connected via `azurerm_virtual_network_gateway_connection`.
- **`attachment_type = "vhub"`** — vWAN ExpressRoute gateway inside an existing
  virtual hub, connected via `azurerm_express_route_connection` against the
  circuit's private peering.

**Independently invocable.** The GatewaySubnet (vnet) or virtual hub ID (vhub) is
a plain input — pass `azure/transit/vwan` outputs as values.

> After `apply`, hand the **service key** output to your connectivity provider.
> The circuit stays `NotProvisioned` until their L2 work completes — keep
> `connect_gateway_to_circuit = false` until then.

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
| service_provider_name | `string` | Connectivity provider | n/a | yes |
| peering_location | `string` | Provider peering site | n/a | yes |
| bandwidth_in_mbps | `number` | Circuit bandwidth | `1000` | no |
| sku_tier | `string` | Standard / Premium / Local | `"Standard"` | no |
| sku_family | `string` | MeteredData / UnlimitedData | `"MeteredData"` | no |
| private_peering | `object` | Peer ASN, dual /30s, VLAN (sensitive) | `{ enabled = false }` | no |
| create_gateway | `bool` | Create ER gateway | `false` | no |
| attachment_type | `string` | `vnet` / `vhub` | `"vnet"` | no |
| gateway_subnet_id | `string` | GatewaySubnet ID (vnet mode) | `null` | conditional |
| gateway_sku | `string` | ER gateway SKU (vnet mode) | `"Standard"` | no |
| virtual_hub_id | `string` | Existing vWAN hub ID (vhub mode) | `null` | conditional |
| er_gateway_scale_units | `number` | vWAN ER gateway scale units (~2 Gbps each) | `1` | no |
| connect_gateway_to_circuit | `bool` | Wire gateway to circuit | `false` | no |
| enable_management_lock | `bool` | CanNotDelete lock | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| circuit_id | Circuit ID |
| service_key | **Sensitive** — give to the provider |
| service_provider_provisioning_state | Provider state |
| gateway_id | ER gateway ID or null |
| connection_ids | `{ gateway = <id> }` or empty |
| private_peering_id | Private peering ID or null |

## Usage

```hcl
module "expressroute" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/hybrid-connectivity/expressroute"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  resource_group_name   = "rg-acme-prod-network"
  location              = "eastus2"
  service_provider_name = "Equinix"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 1000

  private_peering = {
    enabled                       = true
    peer_asn                      = 65010
    primary_peer_address_prefix   = "169.254.30.0/30"
    secondary_peer_address_prefix = "169.254.30.4/30"
    vlan_id                       = 300
  }
}
```

## Cross-cloud divergence

ExpressRoute requires **two BGP sessions per peering** (primary/secondary /30) for
SLA — AWS DX uses one per VIF, GCP one per VLAN attachment, OCI one per virtual
circuit. The circuit and the gateway scale independently; the provider L2 step is
out-of-band on every cloud.

vhub-mode caveat: like all vWAN branch attachments, the ER connection associates
with the hub's **default route table**. Steering branch traffic through a
firewall services VNet (NVA pattern) requires default-table `hub_routes` in
`azure/transit/vwan` — a custom route table cannot capture branch traffic.

## Destroy note

`enable_management_lock` defaults to `true`. Apply with it set to `false` before
destroying.
