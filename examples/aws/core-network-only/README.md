# Example — AWS Core Network Only

Deploys **only** `modules/aws/core-network`: a VPC with two public and two private
subnets across two AZs, a single NAT gateway, and CloudWatch flow logs.

## What is deployed

- VPC (`10.20.0.0/16` by default) with DNS support
- 2 public + 2 private subnets (CIDRs derived via `cidrsubnet`)
- Internet gateway + public route table; per-private-subnet route tables
- 1 NAT gateway (single strategy) with private default routes
- VPC flow logs to a module-managed CloudWatch log group

## Required inputs

None — everything has lab defaults. Override `region`, `vpc_cidr_block`, and the
governance variables for real use.

## How to run

```bash
terraform init
terraform apply
```

## State

`backend.tf` carries the commented S3 + DynamoDB pattern. See
[docs/state-management.md](../../../docs/state-management.md).
