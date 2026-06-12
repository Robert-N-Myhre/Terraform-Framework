# AWS Firewall — Security Groups

Creates a set of stateful security groups with ingress/egress rules, including
SG-to-SG references between groups defined in the same invocation.

**Independently invocable.** The target VPC is supplied by ID; it may come from this
framework's core-network module, an existing VPC, or a data source. No framework
dependency exists.

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
| security_groups | `map(object)` | Groups keyed by logical name with `ingress_rules` / `egress_rules` maps | n/a | yes |
| default_egress_allow_all | `bool` | Add allow-all egress to groups with no explicit egress rules | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → security group ID |
| firewall_arns | Logical name → security group ARN |
| rule_ids | `ingress/<sg>/<rule>` and `egress/<sg>/<rule>` → rule ID |

## Usage

```hcl
module "security_groups" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/firewall/security-groups"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  vpc_id = "vpc-0abc123def456789a"

  security_groups = {
    web = {
      description = "Public web tier"
      ingress_rules = {
        https = { ip_protocol = "tcp", from_port = 443, to_port = 443, cidr_ipv4 = "0.0.0.0/0" }
      }
      egress_rules = {
        to-app = { ip_protocol = "tcp", from_port = 8080, to_port = 8080, referenced_security_group_key = "app" }
      }
    }
    app = {
      description = "Application tier"
      ingress_rules = {
        from-web = { ip_protocol = "tcp", from_port = 8080, to_port = 8080, referenced_security_group_key = "web" }
      }
    }
  }
}
```

## Cross-cloud divergence

AWS security groups are stateful and ENI-scoped, and support direct SG-to-SG
references. Azure NSGs attach to subnets/NICs and reference ASGs; GCP VPC firewall
rules are network-global and target by network tag or service account; OCI offers
subnet-level security lists plus NSGs. The `referenced_security_group_key` pattern
here has no direct GCP equivalent — see the GCP module README for the tag-based
analogue.
