# Example — AWS Security Groups Only

Deploys **only** the `modules/aws/firewall/security-groups` module against an
existing VPC. Demonstrates the framework's primary design constraint: any leaf
module is independently invocable with zero framework dependencies.

## What is deployed

- Two security groups (`web`, `app`) with cross-referencing rules
  (web → app on 8080) — nothing else.

## Required inputs

| Variable | Description |
|----------|-------------|
| `vpc_id` | ID of an existing VPC (e.g., `vpc-0abc...`). |

All other variables have lab-friendly defaults — override `prefix`,
`environment`, `owner`, `cost_center` for real use.

## How to run

```bash
terraform init
terraform plan -var "vpc_id=vpc-0abc123def456789a"
terraform apply -var "vpc_id=vpc-0abc123def456789a"
```

## State

`backend.tf` contains a commented S3 + DynamoDB backend placeholder. Local state
is fine for throwaway labs; uncomment and configure for anything shared. See
[docs/state-management.md](../../../docs/state-management.md).
