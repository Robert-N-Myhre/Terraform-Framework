# OCI DNS — Private Views

Creates private DNS views, each containing private primary zones and record sets
(rrsets).

**Independently invocable.** Views become resolvable from a VCN when attached to its
resolver — do that via the independently invoked `oci/dns/resolver` module or by
OCID in the consumer root.

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
| views | `map(object)` | Views containing zones containing records | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| view_ids | Logical name → view OCID (attach to resolvers) |
| zone_ids | `<view>/<zone>` → zone OCID |
| zone_names | `<view>/<zone>` → domain name |
| record_ids | `<view>/<zone>/<record>` → rrset ID |

## Usage

```hcl
module "private_dns" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/dns/private-views"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "CC-3300"

  compartment_id = "ocid1.compartment.oc1..aaaa..."

  views = {
    internal = {
      zones = {
        prod = {
          domain_name = "prod.internal.example.com"
          records = {
            api = { name = "api", type = "A", rdata = ["10.80.10.15"] }
          }
        }
      }
    }
  }
}
```

## Cross-cloud divergence

OCI scopes private DNS through **views attached to VCN resolvers** — a third model
distinct from AWS zone-VPC associations, Azure VNet links, and GCP network lists.
The same zone name can exist in multiple views with different answers
(view-based split horizon), which no other cloud expresses this directly.
