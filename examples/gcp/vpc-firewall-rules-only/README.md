# Example — GCP VPC Firewall Rules Only

Deploys **only** `modules/gcp/firewall/vpc-firewall-rules` against an existing
network: HTTPS ingress to `web`-tagged instances, the GCP health-check ranges,
and a tag-to-tag rule (web → app on 8080).

## Required inputs

| Variable | Description |
|----------|-------------|
| `project_id` | Project containing the network. |
| `network_name` | Existing VPC network name. |

## How to run

```bash
terraform init
terraform apply -var "project_id=my-project" -var "network_name=my-vpc"
```

## State

`backend.tf` carries the commented GCS pattern. See
[docs/state-management.md](../../../docs/state-management.md).
