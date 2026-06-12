# OCI Hybrid Connectivity — FastConnect

Creates FastConnect virtual circuits — partner model (`provider_service_id`) or
dedicated colocation model (`cross_connect_mappings`) — terminating PRIVATE
circuits on a DRG or advertising `public_prefixes` on PUBLIC circuits.

**Independently invocable.** The DRG and any cross-connects are supplied by OCID.

> The physical layer is out-of-band: partners complete their side after circuit
> creation; dedicated cross-connects (LOA, patching) must exist first.

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
| drg_id | `string` | DRG for PRIVATE circuits | n/a | yes |
| virtual_circuits | `map(object)` | Partner or dedicated circuits, PRIVATE/PUBLIC | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| gateway_id | DRG OCID |
| connection_ids | Logical name → virtual circuit OCID |
| circuit_states | Logical name → BGP + provider states |
| oracle_bgp_asn | Logical name → Oracle-side ASN |

## Usage

```hcl
module "fastconnect" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/hybrid-connectivity/fastconnect"

  prefix      = "acme"
  environment = "prod"
  owner       = "network-team"
  cost_center = "CC-1042"

  compartment_id = "ocid1.compartment.oc1..aaaa..."
  drg_id         = "ocid1.drg.oc1..aaaa..."

  virtual_circuits = {
    primary = {
      bandwidth_shape_name = "1 Gbps"
      provider_service_id  = "ocid1.providerservice.oc1..aaaa..."
      customer_asn         = 65010
    }
  }
}
```

## Cross-cloud divergence

The BGP session lives **on the virtual circuit** (customer/oracle peering IPs) —
AWS puts it on the VIF, Azure on the circuit peering (dual sessions), GCP on the
Cloud Router. PUBLIC circuits (advertising your prefixes over the private link)
parallel AWS public VIFs; GCP has no equivalent.
