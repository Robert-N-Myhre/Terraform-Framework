# Example — OCI Core Network Only

Deploys **only** `modules/oci/core-network`: a VCN with a public subnet (IGW
default route) and a private `app` subnet (NAT default route), plus a service
gateway.

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
