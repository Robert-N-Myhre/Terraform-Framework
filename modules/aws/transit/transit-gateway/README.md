# AWS Transit — Transit Gateway

Creates a transit gateway with VPC attachments, custom route tables, explicit
associations/propagations for segmented topologies, and static (or blackhole) routes.

**Independently invocable.** Attached VPC and subnet IDs are plain inputs. Return
routes inside each spoke VPC (pointing at the TGW) belong to the consumer root
module or to a separately invoked core-network configuration.

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
| amazon_side_asn | `number` | Amazon-side BGP ASN | `64512` | no |
| description | `string` | TGW description | `"Managed by Terraform"` | no |
| enable_default_route_table_association | `bool` | Auto-associate attachments | `false` | no |
| enable_default_route_table_propagation | `bool` | Auto-propagate attachments | `false` | no |
| enable_dns_support | `bool` | DNS support | `true` | no |
| enable_vpn_ecmp_support | `bool` | VPN ECMP | `true` | no |
| auto_accept_shared_attachments | `bool` | Auto-accept RAM-shared attachments | `false` | no |
| vpc_attachments | `map(object)` | Attachments with association/propagation keys | `{}` | no |
| route_tables | `set(string)` | Custom route table names | `[]` | no |
| static_routes | `map(object)` | Static/blackhole routes | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| hub_id | Transit gateway ID |
| hub_arn | Transit gateway ARN |
| attachment_ids | Logical name → attachment ID |
| route_table_ids | Logical name → TGW route table ID (+ `default`) |
| static_route_ids | Logical name → route ID |

## Usage

```hcl
module "tgw" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/transit/transit-gateway"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  route_tables = ["prod", "shared"]

  vpc_attachments = {
    app = {
      vpc_id          = "vpc-0app"
      subnet_ids      = ["subnet-0tgw1", "subnet-0tgw2"]
      route_table_key = "prod"
      propagate_to    = ["shared"]
    }
    shared-services = {
      vpc_id          = "vpc-0shared"
      subnet_ids      = ["subnet-0tgw3", "subnet-0tgw4"]
      route_table_key = "shared"
      propagate_to    = ["prod"]
    }
  }
}
```

## Cross-cloud divergence

TGW segmentation (custom route tables + association/propagation) maps loosely to
Azure vWAN hub route tables, OCI DRG route tables with import distributions, and has
no direct GCP NCC equivalent (NCC spokes share a hub without per-spoke route
tables). Topology designs do not port 1:1 across these.
