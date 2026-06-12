# Example — OCI Security Lists Only

Deploys **only** `modules/oci/firewall/security-lists` against an existing VCN:
one list allowing HTTPS from anywhere, SSH from an admin range, and all egress.
Subnet attachment (`security_list_ids`) is left to the consumer.

## Required inputs

| Variable | Description |
|----------|-------------|
| `compartment_id` | Compartment OCID. |
| `vcn_id` | Existing VCN OCID. |

## How to run

```bash
terraform init
terraform apply \
  -var "compartment_id=ocid1.compartment.oc1..aaaa..." \
  -var "vcn_id=ocid1.vcn.oc1..aaaa..."
```

## State

`backend.tf` shows the OCI Object Storage (S3-compatible) backend pattern. See
[docs/state-management.md](../../../docs/state-management.md).
