# AWS Load Balancer — Network Load Balancer

Creates an L4 NLB with TCP/UDP/TLS listeners, target groups (instance/ip/alb), cross-
zone load balancing, and deletion protection on by default. Target registration is
the consumer's responsibility.

**Independently invocable.** VPC, subnets, and security groups are plain ID inputs.

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
| vpc_id | `string` | Target VPC ID | n/a | yes |
| subnet_ids | `list(string)` | ≥1 subnet (one per AZ) | n/a | yes |
| internal | `bool` | Internal vs internet-facing | `true` | no |
| security_group_ids | `list(string)` | SGs (creation-time only!) | `[]` | no |
| enable_deletion_protection | `bool` | Deletion protection | `true` | no |
| enable_cross_zone_load_balancing | `bool` | Cross-zone distribution | `true` | no |
| target_groups | `map(object)` | TCP/UDP/TLS target groups | n/a | yes |
| listeners | `map(object)` | One target group per listener | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | NLB ARN |
| lb_dns_name | NLB DNS name |
| lb_zone_id | Hosted zone ID for alias records |
| listener_ids | Logical name → listener ARN |
| backend_ids | Logical name → target group ARN |

## Usage

```hcl
module "nlb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/load-balancer/nlb"

  prefix      = "acme"
  environment = "prod"
  owner       = "data-team"
  cost_center = "CC-4200"

  vpc_id     = "vpc-0abc123def456789a"
  subnet_ids = ["subnet-0priv1", "subnet-0priv2"]
  internal   = true

  target_groups = {
    postgres = {
      port        = 5432
      protocol    = "TCP"
      target_type = "ip"
    }
  }

  listeners = {
    postgres = { port = 5432, protocol = "TCP", target_group_key = "postgres" }
  }
}
```

## Cross-cloud divergence

Analogue of Azure Standard LB, GCP passthrough network LB, and OCI NLB. AWS uniquely
terminates TLS at L4 (TLS listeners); GCP passthrough and OCI NLB do not. Security
groups attach to an NLB **only at creation** — adding them later forces replacement.

## Destroy note

`enable_deletion_protection` defaults to `true`. Apply with it set to `false`
before destroying.
