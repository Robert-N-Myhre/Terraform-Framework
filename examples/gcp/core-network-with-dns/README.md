# Example — GCP Core Network + Private DNS (Composition)

Shows the framework's **composition pattern** on GCP: the core-network module's
`network_self_link` output feeds the DNS module's `network_self_links` input.
Neither module references the other internally.

## What is deployed

- A custom-mode VPC with one regional subnet
- A private managed zone (with one A record) visible from that VPC

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
