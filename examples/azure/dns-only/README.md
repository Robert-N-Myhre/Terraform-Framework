# Example — Azure Private DNS Only

Deploys **only** `modules/azure/dns/private-zones`: one private zone with an A
record, linked to an existing VNet.

## Required inputs

| Variable | Description |
|----------|-------------|
| `subscription_id` | Target subscription. |
| `resource_group_name` | Existing resource group name. |
| `vnet_id` | Existing VNet ID for the zone link. |

## How to run

```bash
terraform init
terraform apply \
  -var "subscription_id=00000000-...." \
  -var "resource_group_name=rg-lab" \
  -var "vnet_id=/subscriptions/.../virtualNetworks/vnet-lab"
```

## State

`backend.tf` carries the commented Azure Blob Storage pattern. See
[docs/state-management.md](../../../docs/state-management.md).
