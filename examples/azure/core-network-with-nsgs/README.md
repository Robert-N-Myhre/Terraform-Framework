# Example — Azure Core Network + NSGs (Composition)

Shows the framework's **composition pattern** on Azure: `core-network` subnet
outputs feed the NSG module's `subnet_ids`. Neither module references the other
internally — the example root owns the wiring.

## What is deployed

- A resource group (consumer-owned, created in the example root)
- A VNet with `app` and `data` subnets
- Two NSGs (HTTPS into app; SQL from app to data + deny-all) associated with
  those subnets

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
