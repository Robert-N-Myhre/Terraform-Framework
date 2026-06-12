# AWS Transit — VPC Peering

Creates VPC peering connections (same-region auto-accept or same-account
cross-region), DNS resolution options, and optional route injection on both sides.

**Independently invocable.** VPC and route table IDs are plain inputs. Cross-account
peering acceptance requires a second provider alias and belongs in the consumer root
module — intentionally out of scope.

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
| peerings | `map(object)` | Peerings keyed by logical name: requester/accepter VPC IDs, optional `peer_region`, optional route injection per side | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| connection_ids | Logical name → peering connection ID |
| connection_status | Logical name → acceptance status |
| route_ids | `requester|accepter/<peering>/<rt-id>` → route ID |

## Usage

```hcl
module "peering" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/transit/peering"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  peerings = {
    app-to-shared = {
      requester_vpc_id           = "vpc-0app"
      accepter_vpc_id            = "vpc-0shared"
      requester_route_table_ids  = ["rtb-0app1", "rtb-0app2"]
      requester_destination_cidr = "10.30.0.0/16"
      accepter_route_table_ids   = ["rtb-0shared1"]
      accepter_destination_cidr  = "10.20.0.0/16"
    }
  }
}
```

## Cross-cloud divergence

AWS peering is a requester/accepter handshake; Azure needs two one-way peering
resources; GCP configures peering symmetrically per network; OCI uses LPG pairs.
**No cloud's basic peering is transitive** — for hub-and-spoke use the
transit-gateway (AWS), vwan (Azure), network-connectivity-center (GCP), or drg (OCI)
modules instead.
