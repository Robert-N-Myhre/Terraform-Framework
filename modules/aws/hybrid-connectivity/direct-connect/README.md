# AWS Hybrid Connectivity — Direct Connect

Creates a Direct Connect gateway, optional dedicated connection order, private
virtual interfaces, and VGW/TGW gateway associations with on-premises prefix
filtering.

**Independently invocable.** Existing connection, VGW, and TGW IDs are plain inputs.

> The physical cross-connect (LOA-CFA) is a manual/partner step Terraform cannot
> perform — a newly ordered dedicated connection remains pending until completed.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (mandatory tag) | n/a | yes |
| cost_center | `string` | Cost center (mandatory tag) | n/a | yes |
| additional_tags | `map(string)` | Extra tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| create_connection | `bool` | Order a new dedicated connection | `false` | no |
| connection_bandwidth | `string` | 1Gbps / 10Gbps / 100Gbps | `"1Gbps"` | no |
| connection_location | `string` | DX location code | `null` | conditional |
| existing_connection_id | `string` | Existing/hosted connection ID | `null` | conditional |
| dx_gateway_name | `string` | DXGW name override | `null` | no |
| dx_gateway_asn | `number` | DXGW Amazon-side ASN | `64513` | no |
| private_vifs | `map(object)` | Private VIFs (sensitive: BGP keys) | `{}` | no |
| gateway_associations | `map(object)` | VGW/TGW associations + allowed prefixes | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | DX gateway ID |
| connection_ids | `{ connection = <id> }` |
| vif_ids | Logical name → VIF ID |
| association_ids | Logical name → association ID |
| vif_bgp_auth_keys | **Sensitive** — VIF BGP auth keys |

## Usage

```hcl
module "direct_connect" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/hybrid-connectivity/direct-connect"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  existing_connection_id = "dxcon-fgexample"

  private_vifs = {
    primary = {
      vlan             = 101
      bgp_asn          = 65010
      amazon_address   = "169.254.20.1/30"
      customer_address = "169.254.20.2/30"
      mtu              = 9001
    }
  }

  gateway_associations = {
    prod-tgw = {
      type             = "tgw"
      gateway_id       = "tgw-0123456789abcdef0"
      allowed_prefixes = ["10.20.0.0/16", "10.21.0.0/16"]
    }
  }
}
```

## Cross-cloud divergence

DX = circuit + VIFs + DX gateway. Azure ExpressRoute = circuit + peering + ER
gateway connection; GCP Interconnect = VLAN attachments on Cloud Routers; OCI
FastConnect = virtual circuits on a DRG. `allowed_prefixes` (mandatory thinking for
TGW associations — max 20 prefixes) has different analogues per cloud (route filters
in ExpressRoute, none in GCP).
