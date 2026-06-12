# Azure Hybrid Connectivity — VPN Gateway

Creates site-to-site VPN connectivity in one of two modes:

- **`attachment_type = "vnet"`** (default) — a classic route-based virtual network
  gateway in a `GatewaySubnet`, with local network gateways and IPsec connections
  (optional custom IPsec policies, optional active-active).
- **`attachment_type = "vhub"`** — a vWAN VPN gateway inside an existing virtual
  hub, with VPN sites and vWAN gateway connections. The *same*
  `local_network_gateways` / `connections` variable shapes render as
  `azurerm_vpn_site` / `azurerm_vpn_gateway_connection`.

CanNotDelete lock on the gateway by default in both modes.

**Independently invocable.** The GatewaySubnet (vnet) or virtual hub + WAN IDs
(vhub) are plain inputs — pass `azure/transit/vwan` outputs as values.

> Gateway creation takes **30-45 minutes** in either mode — plan CI timeouts
> accordingly.

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
| attachment_type | `string` | `vnet` / `vhub` | `"vnet"` | no |
| gateway_subnet_id | `string` | GatewaySubnet ID (/27+) | `null` | vnet mode |
| sku | `string` | VpnGw1..3 / AZ variants (no Basic; vnet mode) | `"VpnGw1"` | no |
| generation | `string` | Generation1 / Generation2 (vnet mode) | `"Generation1"` | no |
| active_active | `bool` | Two public IPs / tunnels (vnet mode) | `false` | no |
| virtual_hub_id | `string` | Existing vWAN hub ID | `null` | vhub mode |
| virtual_wan_id | `string` | Owning WAN ID (sites are WAN-scoped) | `null` | vhub mode |
| vpn_gateway_scale_unit | `number` | vWAN gateway scale units (~500 Mbps each) | `1` | no |
| enable_bgp | `bool` | BGP on the gateway (vnet mode) | `true` | no |
| bgp_asn | `number` | Azure-side ASN (vnet mode; vhub is fixed 65515) | `65515` | no |
| local_network_gateways | `map(object)` | On-prem sites (LNGs in vnet mode, VPN sites in vhub mode) | n/a | yes |
| connections | `map(object)` | IPsec connections (sensitive: shared keys) | n/a | yes |
| enable_management_lock | `bool` | CanNotDelete lock | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | VNG ID (vnet) or vWAN VPN gateway ID (vhub) |
| gateway_public_ips | Gateway public IP(s) — vnet mode only (empty in vhub; instance IPs are portal/API-visible post-provision) |
| local_gateway_ids | Logical name → LNG ID (vnet mode) |
| vpn_site_ids | Logical name → VPN site ID (vhub mode) |
| connection_ids | Logical name → connection ID (either mode) |
| bgp_peering_address | Azure-side BGP addresses (vnet mode) or null |

## Usage — vhub mode (vWAN hub gateway)

```hcl
module "vwan_vpn" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/hybrid-connectivity/vpn"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"

  attachment_type = "vhub"
  virtual_hub_id  = "/subscriptions/.../virtualHubs/acme-azure-prod-vhub-east-01"
  virtual_wan_id  = "/subscriptions/.../virtualWans/acme-azure-prod-vwan-01"

  local_network_gateways = {
    dc-east = {
      gateway_address     = "203.0.113.10"
      bgp_asn             = 65020
      bgp_peering_address = "10.250.255.1"
    }
  }

  connections = {
    dc-east = {
      local_network_gateway_key = "dc-east"
      shared_key                = var.vpn_shared_key
    }
  }
}
```

vnet-mode usage is unchanged — see the variables table; set
`attachment_type = "vnet"` (default) and supply `gateway_subnet_id`.

## Cross-cloud divergence

Tunnel count depends on mode: vnet active-active gives two public IPs; the vWAN
gateway always runs two instances. AWS always gives two tunnels per connection,
GCP HA VPN exposes two interfaces, OCI two tunnels per IPSec connection.

vhub-mode caveats:

- The hub router ASN is fixed at **65515** — on-prem peers (and any NVA BGP peers
  on the same hub) must use different ASNs; don't reuse 65515 on-premises.
- **Branch connections always associate with the hub's default route table.**
  Steering branch traffic through a firewall services VNet requires
  default-table `hub_routes` in `azure/transit/vwan` — a custom route table
  cannot capture branch traffic.
- Custom IPsec policies (`ipsec_policy`) apply in vnet mode only.

## Destroy note

`enable_management_lock` defaults to `true`. Apply with it set to `false` before
destroying.
