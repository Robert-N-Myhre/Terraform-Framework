# OCI Transit — Dynamic Routing Gateway

Creates an upgraded DRG with custom DRG route tables, VCN attachments, static DRG
routes, and cross-region Remote Peering Connections.

**Independently invocable.** VCN OCIDs are plain inputs. Return routes inside each
VCN (route rules targeting the DRG OCID) belong to the consumer root.
Hybrid-connectivity modules (`oci/hybrid-connectivity/*`) attach to this DRG by
OCID — never by module reference.

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
| drg_route_tables | `set(string)` | Custom DRG route table names | `[]` | no |
| vcn_attachments | `map(object)` | VCN attachments + optional DRG/VCN route tables | `{}` | no |
| static_routes | `map(object)` | CIDR → attachment routes | `{}` | no |
| remote_peering_connections | `map(object)` | Cross-region RPCs | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| hub_id | DRG OCID |
| attachment_ids | Logical name → attachment OCID |
| route_table_ids | Logical name → DRG route table OCID |
| rpc_ids | Logical name → RPC OCID |

## Usage

```hcl
module "drg" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/transit/drg"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id = "ocid1.compartment.oc1..aaaa..."

  drg_route_tables = ["prod", "shared"]

  vcn_attachments = {
    app = {
      vcn_id              = "ocid1.vcn.oc1..app..."
      drg_route_table_key = "prod"
    }
    shared-services = {
      vcn_id              = "ocid1.vcn.oc1..shared..."
      drg_route_table_key = "shared"
    }
  }

  static_routes = {
    to-shared = {
      drg_route_table_key     = "prod"
      destination_cidr        = "10.81.0.0/16"
      next_hop_attachment_key = "shared-services"
    }
  }
}
```

## Cross-cloud divergence

The closest analogue to AWS TGW (both support per-attachment custom route tables).
The DRG additionally terminates **IPSec VPN and FastConnect** directly and peers
cross-region via RPCs — AWS splits these across VGW/DXGW/TGW peering. Classic
(pre-upgrade) DRGs are not supported by this module.
