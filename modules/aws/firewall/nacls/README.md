# AWS Firewall — Network ACLs

Creates stateless network ACLs with numbered allow/deny rules and optional subnet
associations.

**Independently invocable.** VPC and subnet IDs are plain inputs — they may come from
any source. No framework dependency exists.

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
| name_suffix | `string` | Final naming token | `"01"` | no |
| vpc_id | `string` | Target VPC ID | n/a | yes |
| network_acls | `map(object)` | ACLs keyed by logical name: `ingress_rules`, `egress_rules`, optional `subnet_ids` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → NACL ID |
| firewall_arns | Logical name → NACL ARN |
| rule_ids | `ingress|egress/<acl>/<rule>` → rule ID |
| subnet_association_ids | `<acl>/<subnet-id>` → association ID |

## Usage

```hcl
module "nacls" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/firewall/nacls"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  vpc_id = "vpc-0abc123def456789a"

  network_acls = {
    web-tier = {
      subnet_ids = ["subnet-0aaa111", "subnet-0bbb222"]
      ingress_rules = {
        https     = { rule_number = 100, protocol = "tcp", action = "allow", cidr_block = "0.0.0.0/0", from_port = 443, to_port = 443 }
        ephemeral = { rule_number = 110, protocol = "tcp", action = "allow", cidr_block = "0.0.0.0/0", from_port = 1024, to_port = 65535 }
      }
      egress_rules = {
        all = { rule_number = 100, protocol = "-1", action = "allow", cidr_block = "0.0.0.0/0" }
      }
    }
  }
}
```

## Cross-cloud divergence

NACLs are **stateless**: return traffic must be explicitly allowed (note the
ephemeral-port rule above). Azure NSGs and GCP firewall rules are stateful and infer
return paths; OCI security lists default to stateful but support stateless rules.
Port rules between clouds are therefore not 1:1 portable.
