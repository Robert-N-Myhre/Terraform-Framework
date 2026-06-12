# OCI Transit — Local Peering Gateways

Creates LPG pairs for same-region VCN peering — one gateway in each VCN, connected
by setting `peer_id` on side A.

**Independently invocable.** VCN OCIDs are plain inputs. Adding route rules that
target the LPG OCIDs (in each VCN's route tables) is the consumer's responsibility —
peering alone moves no traffic.

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
| peerings | `map(object)` | VCN pairs + optional LPG route tables (transit routing) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connection_ids | `<peering>/a`, `<peering>/b` → LPG OCID (route-rule targets) |
| peering_status | Logical name → PEERED / etc. |
| peer_advertised_cidrs | Logical name → CIDR advertised by peer |

## Usage

```hcl
module "lpg" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/transit/lpg"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id = "ocid1.compartment.oc1..aaaa..."

  peerings = {
    app-to-shared = {
      vcn_a_id = "ocid1.vcn.oc1..app..."
      vcn_b_id = "ocid1.vcn.oc1..shared..."
    }
  }
}
```

## Cross-cloud divergence

Peering via **gateway objects** (an LPG per side; `peer_id` set on one side only) —
vs AWS handshake / Azure dual one-way / GCP symmetric models. **Same-region only**;
cross-region peering uses Remote Peering Connections on a DRG
(`oci/transit/drg`). Non-transitive, like all basic peering.
