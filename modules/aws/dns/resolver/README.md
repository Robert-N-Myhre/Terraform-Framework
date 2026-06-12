# AWS DNS — Route 53 Resolver

Creates Route 53 Resolver inbound/outbound endpoints, per-domain forwarding (and
SYSTEM override) rules with VPC associations, and optional query logging.

**Independently invocable.** Subnets, security groups, and VPC IDs are plain inputs.
No framework dependency exists.

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
| create_inbound_endpoint | `bool` | Create inbound endpoint | `false` | no |
| inbound_subnet_ids | `list(string)` | ≥2 subnets in distinct AZs when inbound enabled | `[]` | no |
| inbound_security_group_ids | `list(string)` | SGs for inbound ENIs (allow 53/tcp+udp in) | `[]` | no |
| create_outbound_endpoint | `bool` | Create outbound endpoint | `false` | no |
| outbound_subnet_ids | `list(string)` | ≥2 subnets in distinct AZs when outbound enabled | `[]` | no |
| outbound_security_group_ids | `list(string)` | SGs for outbound ENIs (allow 53/tcp+udp out) | `[]` | no |
| forwarding_rules | `map(object)` | FORWARD/SYSTEM rules with `target_ips` and `vpc_ids` | `{}` | no |
| query_log_destination_arn | `string` | CloudWatch/S3/Firehose ARN, null = disabled | `null` | no |
| query_log_vpc_ids | `list(string)` | VPCs associated with query logging | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| inbound_endpoint_id | Inbound endpoint ID or null |
| inbound_endpoint_ips | Inbound ENI IPs (on-prem forwarder targets) |
| outbound_endpoint_id | Outbound endpoint ID or null |
| rule_ids | Logical name → resolver rule ID |
| rule_association_ids | `<rule>/<vpc-id>` → association ID |
| query_log_config_id | Query log config ID or null |

## Usage

```hcl
module "resolver" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/dns/resolver"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "CC-3300"

  create_outbound_endpoint    = true
  outbound_subnet_ids         = ["subnet-0aaa111", "subnet-0bbb222"]
  outbound_security_group_ids = ["sg-0dns53out"]

  forwarding_rules = {
    corp = {
      domain_name = "corp.example.com"
      target_ips  = [{ ip = "10.250.0.10" }, { ip = "10.250.0.11" }]
      vpc_ids     = ["vpc-0abc123def456789a"]
    }
  }
}
```

## Cross-cloud divergence

Azure DNS Private Resolver mirrors the inbound/outbound endpoint shape; GCP uses
zone-level forwarding and DNS server policies instead of per-rule resources; OCI
attaches endpoints to the VCN resolver. FORWARD rules here require the outbound
endpoint created in the same invocation — pass `create_outbound_endpoint = true`.
