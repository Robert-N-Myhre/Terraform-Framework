# OCI Load Balancer — Network Load Balancer

Creates an L4 passthrough NLB (public or private) with hashing-policy backend sets,
TCP/UDP/HTTP(S) health checkers, optional static backend registration
(IP or instance OCID), and TCP/UDP listeners. Supports transparent
source/destination preservation for firewall-appliance insertion.

**Independently invocable.** Subnet and NSG OCIDs are plain inputs.

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
| subnet_id | `string` | NLB subnet | n/a | yes |
| is_private | `bool` | Private NLB | `true` | no |
| is_preserve_source_destination | `bool` | Transparent mode | `false` | no |
| nsg_ids | `list(string)` | Attached NSGs | `[]` | no |
| backend_sets | `map(object)` | Sets with hashing policy + health checker | n/a | yes |
| listeners | `map(object)` | TCP/UDP listeners | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | NLB OCID |
| lb_address | First NLB IP |
| listener_ids | Logical name → listener name |
| backend_ids | Logical name → backend set name |

## Usage

```hcl
module "nlb" {
  source = "github.com/example-org/terraform-multicloud-networking//modules/oci/load-balancer/network-load-balancer"

  prefix      = "acme"
  environment = "prod"
  owner       = "data-team"
  cost_center = "CC-4200"

  compartment_id = "ocid1.compartment.oc1..aaaa..."
  subnet_id      = "ocid1.subnet.oc1..aaaa..."

  backend_sets = {
    postgres = {
      health_checker = { protocol = "TCP", port = 5432 }
      backends = {
        db1 = { ip_address = "10.80.20.11", port = 5432 }
      }
    }
  }

  listeners = {
    postgres = { port = 5432, protocol = "TCP", default_backend_set_key = "postgres" }
  }
}
```

## Cross-cloud divergence

A **separate service** from the OCI LB (different API family). Non-proxying:
client IP preserved, no TLS termination (AWS NLB uniquely offers L4 TLS).
`is_preserve_source_destination = true` enables transparent firewall insertion —
the OCI analogue of AWS TGW appliance mode + GWLB patterns.
