# Azure Transit — Virtual WAN

Creates a Virtual WAN with one or more virtual hubs (per region), VNet-to-hub
connections with full routing configuration (association, propagation including
propagate-to-none isolation, static next-hop-IP routes), custom hub route tables,
static hub routes (custom **or default** route table), hub-router BGP peerings with
NVAs in connected VNets, and a CanNotDelete management lock (on by default).

**Independently invocable.** Spoke VNet IDs are plain inputs. VPN/ExpressRoute
gateways inside the hub belong to the hybrid-connectivity domain — use
`azure/hybrid-connectivity/vpn` and `azure/hybrid-connectivity/expressroute` in
`vhub` mode, passing this module's `hub_id` output as a plain ID.

## Third-party firewall (NVA-in-spoke) support

**Routing intent is deliberately not modeled.** It only accepts in-hub next-hops
(Azure Firewall, integrated hub NVAs, SaaS such as Palo Alto Cloud NGFW) — a
VM-Series-style firewall in a connected services VNet does not qualify. The
supported pattern here:

1. **`hub_routes`** steer traffic (0.0.0.0/0, RFC1918) to the firewall VNet's
   *connection* (`next_hop_type = ResourceId`). Use `route_table_key = null` to
   place routes on the hub **default** route table — required for branch (VPN/ER)
   traffic, since branches can only associate with the default table.
2. **`static_routes` on the firewall connection** carry the next-hop **IP** inside
   the firewall VNet — the internal Standard LB frontend in front of the NVA
   trust interfaces.
3. **Spoke connections** associate with a custom route table
   (`associated_route_table_key`) and isolate with `propagate_none = true`.
4. **`bgp_connections`** (optional) let the NVA eBGP-peer with the hub router
   (fixed ASN **65515**) and advertise routes dynamically.

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
| location | `string` | Region of the WAN resource | n/a | yes |
| wan_type | `string` | Standard / Basic | `"Standard"` | no |
| hubs | `map(object)` | Hubs: location, `/23+` address_prefix, routing preference | n/a | yes |
| vnet_connections | `map(object)` | Spoke connections: association, propagation (`propagate_none`), static next-hop-IP routes | `{}` | no |
| hub_route_tables | `map(object)` | Custom route tables (bare; routes via `hub_routes`) | `{}` | no |
| hub_routes | `map(object)` | Static routes on custom or default tables → connection next-hops | `{}` | no |
| bgp_connections | `map(object)` | Hub-router eBGP peerings with in-VNet NVAs (peer_asn ≠ 65515) | `{}` | no |
| enable_management_lock | `bool` | CanNotDelete lock on the WAN | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| wan_id | Virtual WAN ID |
| hub_id | Logical name → hub ID (pass to hybrid modules in vhub mode) |
| hub_default_route_table_ids | Logical name → default route table ID |
| route_table_ids | Custom tables by key + `default/<hub>` entries |
| attachment_ids | Logical name → hub connection ID |
| hub_route_ids | Logical name → hub route ID |
| bgp_connection_ids | Logical name → BGP connection ID |

## Usage — firewall services hub (VM-Series pattern)

```hcl
module "vwan" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/azure/transit/vwan"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  resource_group_name = "rg-acme-prod-network"
  location            = "eastus2"

  hubs = {
    east = { location = "eastus2", address_prefix = "10.99.0.0/23" }
  }

  hub_route_tables = {
    spokes = { hub_key = "east" }
  }

  vnet_connections = {
    # Firewall services VNet: associates with the DEFAULT table, propagates
    # normally, and carries the next-hop-IP static route to the internal LB
    # in front of the VM-Series trust NICs.
    firewall = {
      hub_key = "east"
      vnet_id = "/subscriptions/.../virtualNetworks/acme-azure-prod-vnet-fw"
      static_routes = {
        inspect = {
          address_prefixes    = ["0.0.0.0/0", "10.0.0.0/8"]
          next_hop_ip_address = "10.90.1.100" # trust-side ILB frontend
        }
      }
    }

    # Spokes: associate with the custom table, propagate to none.
    spoke1 = {
      hub_key                    = "east"
      vnet_id                    = "/subscriptions/.../virtualNetworks/spoke1"
      associated_route_table_key = "spokes"
      propagate_none             = true
    }
  }

  hub_routes = {
    spokes-via-fw = {
      hub_key                 = "east"
      route_table_key         = "spokes"
      destinations            = ["0.0.0.0/0", "10.0.0.0/8"]
      next_hop_connection_key = "firewall"
    }
    # Branch (VPN/ER) traffic lives on the DEFAULT table:
    branches-via-fw = {
      hub_key                 = "east"
      route_table_key         = null
      destinations            = ["10.0.0.0/8"]
      next_hop_connection_key = "firewall"
    }
  }

  # Optional: VM-Series advertises routes via eBGP instead of statics.
  bgp_connections = {
    fw-a = { hub_key = "east", peer_asn = 65010, peer_ip = "10.90.1.11", connection_key = "firewall" }
    fw-b = { hub_key = "east", peer_asn = 65010, peer_ip = "10.90.1.12", connection_key = "firewall" }
  }
}
```

See `examples/azure/vwan-with-nva-firewall/` for the full composition (firewall
VNet + internal LB + spokes).

## Cross-cloud divergence

vWAN hubs embed a managed router and host gateways inside the hub — AWS TGW keeps
gateways as separate attachments; GCP NCC has no hub-resident gateways; OCI DRG
attaches everything by attachment type. Hub `address_prefix` must not overlap any
connected VNet or branch. Hub provisioning takes 20-30 minutes.

vWAN-specific routing caveats:

- **Branches (VPN/ER) always associate with the default route table** — steering
  branch traffic through an NVA requires default-table `hub_routes`, not a custom
  table.
- The hub router ASN is fixed at **65515**; NVA BGP peers must use a different ASN.
- Inter-hub traffic hairpinning through an NVA-in-spoke has documented vWAN
  limitations — keep inspection intra-region or use one firewall VNet per hub.
- Symmetric routing through an ILB-sandwiched NVA pair requires consistent
  association/propagation on **every** spoke connection; one unisolated spoke
  bypasses inspection.

## Destroy note

`enable_management_lock` defaults to `true`. Apply with it set to `false` before
destroying.
