# GCP Transit — VPC Network Peering

Creates both sides of VPC network peering pairs with custom-route export/import
control.

**Independently invocable.** Network self-links are plain inputs. Works across
projects when the provider identity has `compute.networkAdmin` on both.

> Network peerings are **not labelable** — governance tagging is honored via naming
> convention only.

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
| owner | `string` | Convention parity | n/a | yes |
| cost_center | `string` | Convention parity | n/a | yes |
| additional_tags | `map(string)` | Convention parity | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| peerings | `map(object)` | Pairs with per-direction route import/export flags | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connection_ids | `<peering>/a-to-b`, `<peering>/b-to-a` → peering ID |
| connection_states | Same keys → state (ACTIVE when both sides up) |

## Usage

```hcl
module "peering" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/gcp/transit/peering"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "cc-1042"

  peerings = {
    hub-spoke1 = {
      network_a_self_link = "https://www.googleapis.com/compute/v1/projects/acme-hub/global/networks/hub-vpc"
      network_b_self_link = "https://www.googleapis.com/compute/v1/projects/acme-app/global/networks/spoke1-vpc"

      # Share the hub's VPN routes with the spoke:
      a_to_b = { export_custom_routes = true }
      b_to_a = { import_custom_routes = true }
    }
  }
}
```

## Cross-cloud divergence

Symmetric two-sided configuration (both resources required for ACTIVE) vs AWS
handshake / Azure dual one-way / OCI LPG pairs. Subnet routes exchange
automatically; only **custom routes** need the export/import flags. Non-transitive —
use `gcp/transit/network-connectivity-center` for hub-and-spoke.
