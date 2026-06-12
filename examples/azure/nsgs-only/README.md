# Example — Azure NSGs Only

Deploys **only** `modules/azure/firewall/nsgs` into an existing resource group:
one NSG with an allow-HTTPS rule and an explicit deny-all, optionally associated
with existing subnets.

## Required inputs

| Variable | Description |
|----------|-------------|
| `subscription_id` | Target subscription. |
| `resource_group_name` | Existing resource group name. |

`subnet_ids` is optional — leave empty to create the NSG unassociated.

## How to run

```bash
terraform init
terraform apply -var "subscription_id=00000000-...." -var "resource_group_name=rg-lab"
```

## State

`backend.tf` carries the commented Azure Blob Storage pattern. See
[docs/state-management.md](../../../docs/state-management.md).
