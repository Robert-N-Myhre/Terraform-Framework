# OCI Hybrid Connectivity — Site-to-Site IPSec VPN

Creates CPE objects and IPSec connections terminating on a DRG, with per-tunnel
configuration (BGP or static, PSK, IKE version) via tunnel management.

**Independently invocable.** The DRG is supplied by OCID (from `oci/transit/drg`,
an existing DRG, or a data source).

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| oci (oracle/oci) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| oci | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (freeform tag) | n/a | yes |
| cost_center | `string` | Cost center (freeform tag) | n/a | yes |
| additional_tags | `map(string)` | Extra freeform tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| compartment_id | `string` | Compartment OCID | n/a | yes |
| drg_id | `string` | Terminating DRG OCID | n/a | yes |
| customer_premises_equipment | `map(object)` | On-prem device IPs | n/a | yes |
| ipsec_connections | `map(object)` | Connections + per-tunnel config (sensitive) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | DRG OCID |
| cpe_ids | Logical name → CPE OCID |
| connection_ids | Logical name → IPSec connection OCID |
| tunnel_oracle_ips | Logical name → Oracle-side headend IPs (both tunnels) |
| tunnel_status | Logical name → tunnel statuses |

## Usage

```hcl
module "vpn" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/hybrid-connectivity/ipsec-vpn"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id = "ocid1.compartment.oc1..aaaa..."
  drg_id         = "ocid1.drg.oc1..aaaa..."

  customer_premises_equipment = {
    dc-east = { ip_address = "203.0.113.10" }
  }

  ipsec_connections = {
    dc-east = {
      cpe_key = "dc-east"
      tunnels = {
        t1 = {
          tunnel_index          = 1
          customer_bgp_asn      = "65010"
          oracle_interface_ip   = "169.254.50.1/30"
          customer_interface_ip = "169.254.50.2/30"
        }
        t2 = {
          tunnel_index          = 2
          customer_bgp_asn      = "65010"
          oracle_interface_ip   = "169.254.51.1/30"
          customer_interface_ip = "169.254.51.2/30"
        }
      }
    }
  }
}
```

## Cross-cloud divergence

Two tunnels per connection (like AWS), but tunnel configuration goes through a
**management resource that adopts** the auto-created tunnels — unique to OCI.
`static_routes` must be non-empty at the connection level even for pure-BGP
connections (this module supplies a `0.0.0.0/0` placeholder).
