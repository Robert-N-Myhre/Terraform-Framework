# Example — OCI Core Network + NSGs (Composition)

Shows the framework's **composition pattern** on OCI: the core-network module's
`network_id` output feeds the NSG module's `vcn_id` input. Neither module
references the other internally.

## What is deployed

- A VCN with one private `app` subnet (NAT default route)
- Two NSGs (`web`, `app`) with NSG-to-NSG rules (web → app on 8080)

VNIC membership in the NSGs is left to wherever the workloads are managed.

## Required inputs

| Variable | Description |
|----------|-------------|
| `compartment_id` | Compartment OCID. |

## How to run

```bash
terraform init
terraform apply -var "compartment_id=ocid1.compartment.oc1..aaaa..."
```

## State

`backend.tf` shows the OCI Object Storage (S3-compatible) backend pattern. See
[docs/state-management.md](../../../docs/state-management.md).
