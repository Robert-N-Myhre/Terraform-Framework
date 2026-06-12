# OCI Firewall — OCI Network Firewall

Creates an OCI Network Firewall (Palo Alto-backed) with a policy composed of
address lists, service lists, and ALLOW/DROP/REJECT/INSPECT security rules, plus
the firewall instance in a dedicated subnet.

**Independently invocable.** The firewall subnet is a plain OCID input. Steering
traffic through the firewall (VCN route rules to `firewall_private_ip`) is the
consumer's job.

> Firewall provisioning takes ~30 minutes and incurs significant hourly cost —
> verify SKU pricing before lab use.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| oci (oracle/oci) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| oci | ~> 5.0 |

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| prefix | `string` | Short org/project prefix | n/a | yes |
| environment | `string` | Environment identifier | n/a | yes |
| owner | `string` | Owning team (freeform tag) | n/a | yes |
| cost_center | `string` | Cost center (freeform tag) | n/a | yes |
| additional_tags | `map(string)` | Extra freeform tags | `{}` | no |
| name_suffix | `string` | Final naming token | `"01"` | no |
| compartment_id | `string` | Compartment OCID | n/a | yes |
| firewall_subnet_id | `string` | Dedicated subnet OCID | n/a | yes |
| availability_domain | `string` | AD (null = OCI chooses) | `null` | no |
| ipv4_address | `string` | Static firewall IP | `null` | no |
| address_lists | `map(list(string))` | Named CIDR lists | `{}` | no |
| service_lists | `map(map(object))` | Named service (port) lists | `{}` | no |
| security_rules | `map(object)` | Rules referencing lists by name | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | `{ firewall = <OCID> }` |
| firewall_private_ip | Route-rule target IP |
| policy_id | Policy OCID |
| rule_ids | Logical name → policy rule name |

## Usage

```hcl
module "network_firewall" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/firewall/network-firewall"

  prefix      = "acme"
  environment = "prod"
  owner       = "security-team"
  cost_center = "CC-2001"

  compartment_id     = "ocid1.compartment.oc1..aaaa..."
  firewall_subnet_id = "ocid1.subnet.oc1..aaaa..."

  address_lists = {
    internal = ["10.80.0.0/16"]
    anywhere = ["0.0.0.0/0"]
  }

  service_lists = {
    web = {
      https = { protocol = "TCP", min_port = 443 }
    }
  }

  security_rules = {
    allow-egress-https = {
      position_order            = 1
      action                    = "ALLOW"
      source_address_lists      = ["internal"]
      destination_address_lists = ["anywhere"]
      service_lists             = ["web"]
    }
  }
}
```

## Cross-cloud divergence

Policy composes from **list sub-resources** — vs AWS's Suricata `rules_string`,
Azure's rule collection groups, GCP's policy attachments. Unmatched traffic is
dropped by default. Rule syntax does not port across clouds; document intent
separately.
