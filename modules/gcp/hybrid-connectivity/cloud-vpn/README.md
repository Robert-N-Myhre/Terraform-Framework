# GCP Hybrid Connectivity — HA Cloud VPN

Creates an HA VPN gateway (two interfaces), a Cloud Router, external peer gateways
(one- or two-interface), and IPsec tunnels each with a BGP session
(router interface + peer).

**Independently invocable.** The network self-link is a plain input. For the 99.99%
SLA, define 2 (or 4) tunnels spread across both gateway interfaces and both peer
interfaces.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (label) | n/a | yes |
| cost_center | `string` | Cost center (label) | n/a | yes |
| additional_tags | `map(string)` | Extra labels | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| project_id | `string` | GCP project ID | n/a | yes |
| region | `string` | Gateway/router region | n/a | yes |
| network_self_link | `string` | VPC self-link | n/a | yes |
| router_asn | `number` | Google-side ASN | `64514` | no |
| peer_gateways | `map(object)` | On-prem gateways (1-2 interfaces) | n/a | yes |
| tunnels | `map(object)` | Tunnels + BGP sessions (sensitive: PSKs) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | HA VPN gateway ID |
| gateway_interface_ips | Interface 0/1 → Google-side public IP |
| router_id | Cloud Router ID |
| connection_ids | Logical name → tunnel ID |
| tunnel_self_links | Logical name → self-link (NCC spoke URIs) |
| bgp_peer_ids | Logical name → router peer ID |

## Usage

```hcl
module "vpn" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/hybrid-connectivity/cloud-vpn"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "cc-1042"

  project_id        = "acme-prod-networking"
  region            = "us-east1"
  network_self_link = "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/global/networks/acme-gcp-prod-vpc-01"

  peer_gateways = {
    dc-east = { interfaces = ["203.0.113.10", "203.0.113.11"] }
  }

  tunnels = {
    t0 = {
      peer_gateway_key                = "dc-east"
      peer_external_gateway_interface = 0
      vpn_gateway_interface           = 0
      shared_secret                   = var.vpn_psk_0
      bgp_session_range               = "169.254.40.1/30"
      peer_bgp_ip                     = "169.254.40.2"
      peer_asn                        = 65010
    }
    t1 = {
      peer_gateway_key                = "dc-east"
      peer_external_gateway_interface = 1
      vpn_gateway_interface           = 1
      shared_secret                   = var.vpn_psk_1
      bgp_session_range               = "169.254.41.1/30"
      peer_bgp_ip                     = "169.254.41.2"
      peer_asn                        = 65010
    }
  }
}
```

## Cross-cloud divergence

Routing is **always BGP** in HA VPN — no static-route option (AWS/Azure/OCI all
offer static). One gateway with two interfaces vs AWS's two-tunnels-per-connection.
Classic (target) VPN gateways are deprecated and intentionally unsupported.
