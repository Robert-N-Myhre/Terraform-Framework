# Example — Azure Core Network Only

Deploys **only** `modules/azure/core-network` (plus a resource group created in
the example root — RG lifecycle is always the consumer's): a VNet with two
subnets, per-subnet route tables, and a NAT gateway on the `app` subnet.

The management lock is disabled here for painless lab teardown — leave the
module default (`true`) in real environments.

## Required inputs

| Variable | Description |
|----------|-------------|
| `subscription_id` | Target subscription. |

## How to run

```bash
terraform init
terraform apply -var "subscription_id=00000000-...."
```

## State

`backend.tf` carries the commented Azure Blob Storage pattern. See
[docs/state-management.md](../../../docs/state-management.md).
