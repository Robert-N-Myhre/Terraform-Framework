# Example — GCP Private DNS Only

Deploys **only** `modules/gcp/dns/private-zones`: one private managed zone (with
an A record) visible from an existing VPC.

> The zone `domain_name` must end with a **trailing dot**
> (`dev.internal.example.com.`).

## Required inputs

| Variable | Description |
|----------|-------------|
| `project_id` | Target project. |
| `network_self_link` | Existing VPC self-link for zone visibility. |

## How to run

```bash
terraform init
terraform apply \
  -var "project_id=my-project" \
  -var "network_self_link=https://www.googleapis.com/compute/v1/projects/my-project/global/networks/my-vpc"
```

## State

`backend.tf` carries the commented GCS pattern. See
[docs/state-management.md](../../../docs/state-management.md).
