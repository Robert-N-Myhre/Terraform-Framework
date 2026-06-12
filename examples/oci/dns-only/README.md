# Example — OCI Private DNS Only

Deploys **only** `modules/oci/dns/private-views`: one private view containing one
zone with an A record. Resolution from a VCN requires attaching the view to that
VCN's resolver — a separate, independent step (see `oci/dns/resolver`).

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
