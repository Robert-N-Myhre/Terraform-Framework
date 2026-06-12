# AWS Core Network

Creates a VPC with subnets, route tables, an optional internet gateway, optional NAT
gateways (single or per-AZ), and optional VPC flow logs delivered to a module-managed
CloudWatch log group.

**Independently invocable.** This module sources no other module in this framework and
requires nothing to pre-exist. State backend configuration is the consumer's
responsibility (see `docs/state-management.md`).

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
| environment | `string` | Environment identifier (dev/test/prod) | n/a | yes |
| owner | `string` | Owning team or individual (mandatory tag) | n/a | yes |
| cost_center | `string` | Cost center code (mandatory tag) | n/a | yes |
| additional_tags | `map(string)` | Extra tags merged beneath mandatory tags | `{}` | no |
| name_suffix | `string` | Final naming token for instance disambiguation | `"01"` | no |
| region | `string` | AWS region for all resources | n/a | yes |
| vpc_cidr_block | `string` | IPv4 CIDR for the VPC | n/a | yes |
| enable_dns_support | `bool` | Enable VPC DNS resolution | `true` | no |
| enable_dns_hostnames | `bool` | Enable Amazon-provided DNS hostnames | `true` | no |
| subnets | `map(object)` | Subnet map: `cidr_block`, `availability_zone`, `tier` (public/private), optional `map_public_ip_on_launch` | n/a | yes |
| enable_internet_gateway | `bool` | Create IGW + public default route | `true` | no |
| enable_nat_gateway | `bool` | Create NAT gateway(s) for private egress | `false` | no |
| nat_gateway_strategy | `string` | `single` or `per_az` | `"single"` | no |
| enable_flow_logs | `bool` | Enable VPC flow logs to CloudWatch | `false` | no |
| flow_log_retention_days | `number` | Log group retention | `30` | no |
| flow_log_traffic_type | `string` | ACCEPT / REJECT / ALL | `"ALL"` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | VPC ID |
| network_cidr | VPC CIDR block |
| network_arn | VPC ARN |
| subnet_ids | Map of logical subnet name → subnet ID |
| subnet_cidrs | Map of logical subnet name → CIDR |
| route_table_ids | Public table (key `public`) plus per-private-subnet tables |
| internet_gateway_id | IGW ID or null |
| nat_ids | AZ → NAT gateway ID |
| nat_public_ips | AZ → NAT public IP |
| flow_log_id | Flow log ID or null |

## Usage

```hcl
module "core_network" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/core-network"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  region         = "us-east-1"
  vpc_cidr_block = "10.20.0.0/16"

  subnets = {
    public-a  = { cidr_block = "10.20.0.0/24", availability_zone = "us-east-1a", tier = "public" }
    public-b  = { cidr_block = "10.20.1.0/24", availability_zone = "us-east-1b", tier = "public" }
    private-a = { cidr_block = "10.20.10.0/24", availability_zone = "us-east-1a", tier = "private" }
    private-b = { cidr_block = "10.20.11.0/24", availability_zone = "us-east-1b", tier = "private" }
  }

  enable_nat_gateway   = true
  nat_gateway_strategy = "per_az"
  enable_flow_logs     = true
}
```

## Notes

- Private subnets each get their own route table so separately-invoked transit or
  hybrid-connectivity modules can inject routes per subnet without contention.
- NAT routing prefers the same-AZ gateway and falls back to the first gateway when
  `nat_gateway_strategy = "single"`.
