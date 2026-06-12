# Example — GCP Core Network Only

Deploys **only** `modules/gcp/core-network`: a custom-mode VPC with two regional
subnets (flow logs on `app`), plus Cloud NAT (router + NAT).

## Required inputs

| Variable | Description |
|----------|-------------|
| `project_id` | Target project. |

## How to run

```bash
terraform init
terraform apply -var "project_id=my-project"
```

## State

`backend.tf` carries the commented GCS pattern. See
[docs/state-management.md](../../../docs/state-management.md).
