# OCI DNS — VCN Resolver

Manages a VCN's implicit DNS resolver: attached private views, listening (inbound)
endpoints, forwarding (outbound) endpoints, and conditional FORWARD rules.

**Independently invocable.** The resolver OCID, subnet OCIDs, NSG OCIDs, and view
OCIDs are plain inputs.

> OCI creates the VCN resolver **implicitly with the VCN** — this module manages
> the existing resolver. Get its OCID in the consumer root:
>
> ```hcl
> data "oci_core_vcn_dns_resolver_association" "this" { vcn_id = var.vcn_id }
> # -> data.oci_core_vcn_dns_resolver_association.this.dns_resolver_id
> ```

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
| resolver_id | `string` | Implicit VCN resolver OCID | n/a | yes |
| attached_view_ids | `list(string)` | Views to attach (order = precedence) | `[]` | no |
| listening_endpoints | `map(object)` | Inbound endpoints | `{}` | no |
| forwarding_endpoints | `map(object)` | Outbound endpoints | `{}` | no |
| forward_rules | `map(object)` | Conditional forwarding rules | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| resolver_id | Managed resolver OCID |
| inbound_endpoint_ips | Logical name → listening IP (on-prem forwarder target) |
| outbound_endpoint_ips | Logical name → forwarding IP |
| rule_ids | Logical name → covered domains |

## Usage

```hcl
module "resolver" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/dns/resolver"

  prefix      = "acme"
  environment = "prod"
  owner       = "platform-team"
  cost_center = "CC-3300"

  resolver_id       = data.oci_core_vcn_dns_resolver_association.this.dns_resolver_id
  attached_view_ids = ["ocid1.dnsview.oc1..aaaa..."]

  listening_endpoints  = { main = { subnet_id = "ocid1.subnet.oc1..aaaa..." } }
  forwarding_endpoints = { main = { subnet_id = "ocid1.subnet.oc1..aaaa..." } }

  forward_rules = {
    corp = {
      domain_names            = ["corp.example.com"]
      forwarding_endpoint_key = "main"
      destination_addresses   = ["10.250.0.10"]
    }
  }
}
```

## Cross-cloud divergence

Everything hangs off the **per-VCN resolver** (views, endpoints, inline rules) —
AWS/Azure split these into endpoint/rule/association resources; GCP uses zone types
plus server policies. Attached-view **order matters**: earlier views win on
conflicting names.
