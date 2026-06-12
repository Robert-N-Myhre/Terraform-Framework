# AWS Hybrid Connectivity — Site-to-Site VPN

Creates customer gateways and site-to-site VPN connections terminating on either a
module-managed virtual private gateway (`attachment_type = "vgw"`) or an existing
transit gateway (`attachment_type = "tgw"`). Supports BGP (preferred) or static
routing, custom tunnel inside CIDRs, IKEv2, and VGW route propagation.

**Independently invocable.** VPC or TGW IDs are plain inputs.

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
| attachment_type | `string` | `vgw` or `tgw` | `"vgw"` | no |
| vpc_id | `string` | VPC for the VGW (vgw mode) | `null` | conditional |
| transit_gateway_id | `string` | Existing TGW (tgw mode) | `null` | conditional |
| amazon_side_asn | `number` | VGW Amazon-side ASN | `64512` | no |
| customer_gateways | `map(object)` | On-prem device IP + BGP ASN | n/a | yes |
| vpn_connections | `map(object)` | Connections (sensitive: PSKs) | n/a | yes |
| enable_route_propagation | `list(string)` | VPC route tables learning VGW routes | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | VGW ID (vgw) or supplied TGW ID (tgw) |
| customer_gateway_ids | Logical name → CGW ID |
| connection_ids | Logical name → VPN connection ID |
| tunnel_addresses | Logical name → AWS-side tunnel outside IPs |
| tunnel_preshared_keys | **Sensitive** — tunnel PSKs |

## Usage

```hcl
module "vpn" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/hybrid-connectivity/vpn"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  attachment_type = "vgw"
  vpc_id          = "vpc-0abc123def456789a"

  customer_gateways = {
    dc-east = { bgp_asn = 65010, ip_address = "203.0.113.10" }
  }

  vpn_connections = {
    dc-east-primary = {
      customer_gateway_key = "dc-east"
      tunnel1_inside_cidr  = "169.254.10.0/30"
      tunnel2_inside_cidr  = "169.254.11.0/30"
    }
  }

  enable_route_propagation = ["rtb-0priv1", "rtb-0priv2"]
}
```

## Cross-cloud divergence

AWS always provisions **two tunnels per connection**. Azure VPN Gateway tunnel count
depends on active-active mode; GCP HA VPN exposes two interfaces on one gateway; OCI
IPSec also carries two tunnels but with a different BGP session model. On-premises
device configurations are cloud-specific.
