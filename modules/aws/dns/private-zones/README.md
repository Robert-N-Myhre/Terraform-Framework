# AWS DNS — Route 53 Private Hosted Zones

Creates Route 53 private hosted zones with inline VPC associations and optional
record sets.

**Independently invocable.** VPC IDs are plain inputs; no framework dependency exists.

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
| prefix | `string` | Short org/project prefix; first naming token | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (mandatory tag) | n/a | yes |
| cost_center | `string` | Cost center code (mandatory tag) | n/a | yes |
| additional_tags | `map(string)` | Extra tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| private_zones | `map(object)` | Zones keyed by logical name: `domain_name`, `vpc_associations` (≥1), optional `records` map | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| zone_ids | Logical name → hosted zone ID |
| zone_names | Logical name → domain name |
| zone_arns | Logical name → zone ARN |
| record_ids | `<zone>/<record>` → record FQDN |

## Usage

```hcl
module "private_dns" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/dns/private-zones"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "CC-3300"

  private_zones = {
    internal = {
      domain_name = "prod.internal.example.com"
      vpc_associations = [
        { vpc_id = "vpc-0abc123def456789a" }
      ]
      records = {
        api = { name = "api", type = "A", ttl = 300, values = ["10.20.10.15"] }
        db  = { name = "db", type = "CNAME", values = ["db-primary.prod.internal.example.com"] }
      }
    }
  }
}
```

## Cross-cloud divergence

Route 53 binds VPCs inline on the zone; Azure Private DNS uses standalone
`virtual_network_link` resources; GCP private zones take network self-link lists;
OCI scopes resolution through resolver views. Cross-account association requires
`aws_route53_vpc_association_authorization` in the consumer root — intentionally out
of scope here to preserve module independence.
