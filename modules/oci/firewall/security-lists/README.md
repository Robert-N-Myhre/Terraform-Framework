# OCI Firewall — Security Lists

Creates subnet-level security lists with stateful (default) or stateless rules over
TCP/UDP/ICMP with port and ICMP-type options.

**Independently invocable.** The VCN is supplied by OCID. Attaching lists to subnets
(`security_list_ids` on the subnet) is the consumer's responsibility — a subnet
accepts up to 5 lists.

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
| vcn_id | `string` | VCN OCID | n/a | yes |
| security_lists | `map(object)` | Lists with `ingress_rules` / `egress_rules` (IANA protocol numbers) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → security list OCID |
| rule_ids | Logical name → rule counts (rules are inline, no standalone IDs) |

## Usage

```hcl
module "security_lists" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/firewall/security-lists"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id = "ocid1.compartment.oc1..aaaa..."
  vcn_id         = "ocid1.vcn.oc1..aaaa..."

  security_lists = {
    web = {
      ingress_rules = {
        https = { protocol = "6", source = "0.0.0.0/0", tcp_min = 443 }
      }
      egress_rules = {
        all = { protocol = "all", destination = "0.0.0.0/0" }
      }
    }
  }
}
```

## Cross-cloud divergence

Subnet-level like AWS NACLs but **stateful by default** (per-rule stateless
opt-out) — the inverse of NACLs. Protocols are IANA numbers as strings (`"6"`,
`"17"`, `"1"`) not names. For VNIC-level control, use `oci/firewall/nsgs` instead —
OCI is the only cloud offering both models side by side.
