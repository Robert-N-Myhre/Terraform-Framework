# AWS Firewall — AWS Network Firewall

Creates an AWS Network Firewall with stateless and stateful (Suricata-compatible,
STRICT_ORDER) rule groups, a firewall policy, endpoint placement across dedicated
subnets, optional CloudWatch logging, and deletion protection on by default.

**Independently invocable.** VPC and subnet IDs are plain inputs. No framework
dependency exists. Routing traffic through the firewall endpoints (via route tables)
is intentionally left to the consumer's root module — see `endpoint_ids` output.

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
| vpc_id | `string` | Target VPC ID | n/a | yes |
| firewall_subnet_ids | `list(string)` | Dedicated endpoint subnets (one per AZ) | n/a | yes |
| stateless_rule_groups | `map(object)` | Stateless groups: capacity, priority, rules | `{}` | no |
| stateful_rule_groups | `map(object)` | Stateful groups: capacity, priority, Suricata `rules_string` | `{}` | no |
| stateless_default_actions | `list(string)` | Default stateless actions | `["aws:forward_to_sfe"]` | no |
| stateless_fragment_default_actions | `list(string)` | Default fragment actions | `["aws:forward_to_sfe"]` | no |
| stateful_default_actions | `list(string)` | STRICT_ORDER defaults | `["aws:drop_strict", "aws:alert_strict"]` | no |
| delete_protection | `bool` | Firewall deletion protection | `true` | no |
| subnet_change_protection | `bool` | Prevent endpoint subnet changes | `true` | no |
| policy_change_protection | `bool` | Prevent policy re-association | `false` | no |
| enable_logging | `bool` | ALERT + FLOW logs to CloudWatch | `false` | no |
| log_retention_days | `number` | Log retention | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | `{ firewall = <ARN> }` |
| firewall_policy_arn | Policy ARN |
| rule_ids | `stateless|stateful/<group>` → rule group ARN |
| endpoint_ids | AZ → VPC endpoint ID (route target) |
| log_group_names | ALERT/FLOW log group names |

## Usage

```hcl
module "network_firewall" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/aws/firewall/network-firewall"

  prefix      = "acme"
  environment = "prod"
  owner       = "security-team"
  cost_center = "CC-2001"

  vpc_id              = "vpc-0abc123def456789a"
  firewall_subnet_ids = ["subnet-0fw1", "subnet-0fw2"]

  stateful_rule_groups = {
    baseline = {
      capacity = 100
      priority = 10
      rules_string = <<-EOT
        pass tls $HOME_NET any -> $EXTERNAL_NET 443 (sid:1000001; rev:1;)
        drop ip any any -> any any (msg:"default deny"; sid:1000999; rev:1;)
      EOT
    }
  }

  enable_logging = true
}
```

## Cross-cloud divergence

AWS Network Firewall inserts as VPC endpoints that you must route traffic through;
Azure Firewall is a hub appliance reached via UDRs; OCI Network Firewall is a
Palo Alto-backed appliance; GCP's closest analogue (Cloud NGFW) uses firewall policy
attachments rather than routed endpoints. **Suricata rule syntax does not port** to
the other clouds — keep rule intent documented separately from syntax.

## Destroy note

`delete_protection` defaults to `true`. To destroy, first apply with
`delete_protection = false`, then run destroy.
