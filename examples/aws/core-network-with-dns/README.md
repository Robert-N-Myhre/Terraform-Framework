# Example — AWS Core Network + Private DNS (Composition)

Shows the framework's **composition pattern**: two independently invocable
modules wired together in the example root. `module.core_network.network_id`
feeds the DNS module's `vpc_associations` — neither module references the other
internally; the consumer owns the wiring.

## What is deployed

- A private-only VPC with two private subnets (no IGW/NAT)
- A Route 53 private zone associated with that VPC, with one A record

## Required inputs

None — lab defaults throughout.

## How to run

```bash
terraform init
terraform apply
```

## State

`backend.tf` carries the commented S3 + DynamoDB pattern. See
[docs/state-management.md](../../../docs/state-management.md).
