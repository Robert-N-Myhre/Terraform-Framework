# GCP Hybrid Connectivity — Cloud Interconnect

Creates a Cloud Router and Interconnect VLAN attachments — PARTNER (pairing key
handed to a service provider, who establishes BGP) or DEDICATED (bound to a
physical interconnect with a module-managed BGP session).

**Independently invocable.** The network self-link and physical interconnect
self-link are plain inputs.

> The physical Dedicated Interconnect port (LOA-CFA, cross-connect) is ordered
> out-of-band — Terraform cannot perform that step.

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
| region | `string` | Router/attachment region | n/a | yes |
| network_self_link | `string` | VPC self-link | n/a | yes |
| router_asn | `number` | Google-side ASN (16550 for PARTNER) | `16550` | no |
| attachments | `map(object)` | PARTNER or DEDICATED attachments | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | Cloud Router ID |
| connection_ids | Logical name → attachment ID |
| attachment_self_links | Logical name → self-link (NCC spoke URIs) |
| pairing_keys | **Sensitive** — PARTNER pairing keys |
| cloud_router_ip_addresses | Logical name → Google-side BGP address |

## Usage

```hcl
module "interconnect" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/hybrid-connectivity/cloud-interconnect"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "cc-1042"

  project_id        = "acme-prod-networking"
  region            = "us-east1"
  network_self_link = "https://www.googleapis.com/compute/v1/projects/acme-prod-networking/global/networks/acme-gcp-prod-vpc-01"

  attachments = {
    partner-a = {
      type                     = "PARTNER"
      edge_availability_domain = "AVAILABILITY_DOMAIN_1"
    }
    partner-b = {
      type                     = "PARTNER"
      edge_availability_domain = "AVAILABILITY_DOMAIN_2"
    }
  }
}
```

## Cross-cloud divergence

The BGP speaker is the **Cloud Router**, not the attachment — AWS puts BGP on the
VIF, Azure on the circuit peering, OCI on the virtual circuit. PARTNER attachments
delegate BGP entirely to the provider; partner ASN is fixed at 16550. Use both edge
availability domains for the 99.9%/99.99% SLA topologies.
