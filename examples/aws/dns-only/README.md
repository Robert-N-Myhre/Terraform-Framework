# Example — AWS Private DNS Only

Deploys **only** `modules/aws/dns/private-zones`: one Route 53 private hosted
zone (with A and CNAME records) associated with an existing VPC.

## Required inputs

| Variable | Description |
|----------|-------------|
| `vpc_id` | ID of an existing VPC for the zone association. |

## How to run

```bash
terraform init
terraform apply -var "vpc_id=vpc-0abc123def456789a"
```

## State

`backend.tf` carries the commented S3 + DynamoDB pattern. See
[docs/state-management.md](../../../docs/state-management.md).
