# OCI Firewall — Network Security Groups

Creates VNIC-level NSGs with standalone security rules supporting CIDR, service,
and NSG-to-NSG references (within this invocation via `nsg_key`, or external via
`external_nsg_id`).

**Independently invocable.** The VCN is supplied by OCID. VNIC membership is
declared where workloads are managed (instances, LBs, DB systems) — outside this
module by design.

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
| network_security_groups | `map(object)` | NSGs with rules (exactly one of cidr/service/nsg_key/external_nsg_id per rule) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| firewall_ids | Logical name → NSG OCID |
| rule_ids | `<nsg>/<rule>` → rule OCID |

## Usage

```hcl
module "nsgs" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/firewall/nsgs"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id = "ocid1.compartment.oc1..aaaa..."
  vcn_id         = "ocid1.vcn.oc1..aaaa..."

  network_security_groups = {
    web = {
      rules = {
        https-in = { direction = "INGRESS", protocol = "6", cidr = "0.0.0.0/0", tcp_min = 443 }
        to-app   = { direction = "EGRESS", protocol = "6", nsg_key = "app", tcp_min = 8080 }
      }
    }
    app = {
      rules = {
        from-web = { direction = "INGRESS", protocol = "6", nsg_key = "web", tcp_min = 8080 }
      }
    }
  }
}
```

## Cross-cloud divergence

The closest OCI analogue to AWS security groups (VNIC-scoped, NSG-to-NSG
references, standalone rule resources). OCI uniquely runs **both** NSGs and
subnet-level security lists — effective rules are the **union** of both; keep one
as the system of record to avoid confusion.
