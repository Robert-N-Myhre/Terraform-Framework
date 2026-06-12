# AWS Load Balancer — Application Load Balancer

Creates an ALB with target groups, HTTP/HTTPS listeners (TLS 1.3 policy by default),
path/host routing rules, optional access logs, and deletion protection on by default.
Target registration is the consumer's responsibility (ASG/ECS attachment or
`aws_lb_target_group_attachment` in the root module).

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
| subnet_ids | `list(string)` | ≥2 subnets in distinct AZs | n/a | yes |
| internal | `bool` | Internal vs internet-facing | `false` | no |
| security_group_ids | `list(string)` | SGs attached to the ALB | n/a | yes |
| enable_deletion_protection | `bool` | Deletion protection | `true` | no |
| drop_invalid_header_fields | `bool` | Drop invalid HTTP headers | `true` | no |
| idle_timeout | `number` | Idle timeout (s) | `60` | no |
| access_logs | `object` | `{ enabled, bucket, prefix }` | `{ enabled = false }` | no |
| target_groups | `map(object)` | Target groups with health checks and stickiness | n/a | yes |
| listeners | `map(object)` | Listeners with default action and routing rules | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | ALB ARN |
| lb_dns_name | ALB DNS name |
| lb_zone_id | Hosted zone ID for alias records |
| listener_ids | Logical name → listener ARN |
| backend_ids | Logical name → target group ARN |
| listener_rule_ids | `<listener>/<rule>` → rule ARN |

## Usage

```hcl
module "alb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/load-balancer/alb"

  prefix      = "acme"
  environment = "prod"
  owner       = "web-team"
  cost_center = "CC-4100"

  vpc_id             = "vpc-0abc123def456789a"
  subnet_ids         = ["subnet-0pub1", "subnet-0pub2"]
  security_group_ids = ["sg-0web443"]

  target_groups = {
    web = {
      port     = 8080
      protocol = "HTTP"
      health_check = { path = "/healthz" }
    }
  }

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:us-east-1:111122223333:certificate/abcd-1234"
      default_action  = { type = "forward", target_group_key = "web" }
    }
    http-redirect = {
      port           = 80
      protocol       = "HTTP"
      default_action = { type = "redirect" }
    }
  }
}
```

## Cross-cloud divergence

ALB decomposes into LB + listeners + rules + target groups. Azure Application
Gateway is one resource with inner blocks; GCP external HTTP(S) LB chains forwarding
rule → target proxy → URL map → backend service; OCI uses listener + backend set
inside the LB. Health-check defaults differ — do not assume parity when porting.

## Destroy note

`enable_deletion_protection` defaults to `true`. Apply with it set to `false`
before destroying.
