# Governance — Resource Locks & Deletion Protection

> **This directory is documentation only.** It is not a callable Terraform
> module. Each leaf module implements the protections described here natively,
> on by default, where its cloud supports them.

## Principle

Stateful or connectivity-critical resources — networks, firewalls, transit hubs,
VPN/circuit gateways, load balancers — must not be destroyable by a single
accidental `terraform destroy` or console click. Every module that creates such
a resource enables the strongest native protection **by default** and exposes a
variable to disable it for intentional teardown.

## Provider-specific implementation

### AWS — resource-native flags

AWS has no generic lock; protection is per-resource-type:

| Resource | Mechanism | Module default |
|----------|-----------|----------------|
| Network Firewall | `delete_protection`, `subnet_change_protection` | `true` |
| ALB / NLB | `enable_deletion_protection` | `true` |

VPCs/TGWs have no native flag — protect them with IAM (`Deny ec2:DeleteVpc`,
`ec2:DeleteTransitGateway` except for break-glass roles) and SCPs at the
organization level.

### Azure — management locks

`azurerm_management_lock` with `lock_level = "CanNotDelete"` is applied by
default (variable `enable_management_lock`) to:

- Virtual networks (`azure/core-network`)
- Azure Firewall (`azure/firewall/azure-firewall`)
- Virtual WAN (`azure/transit/vwan`)
- VPN gateways (`azure/hybrid-connectivity/vpn` — covers both the classic VNet
  gateway and the vWAN hub VPN gateway, whichever `attachment_type` creates)
- ExpressRoute circuits (`azure/hybrid-connectivity/expressroute`; the lock
  protects the circuit — vWAN ER gateways in vhub mode are recreatable and
  intentionally unlocked)

Note: a lock blocks **deletes from any principal**, including Terraform itself.

### GCP — liens and org policy

GCP has no per-resource delete lock for networking resources. The framework
relies on:

- **Project liens** (`gcloud alpha resource-manager liens create`) to block
  deletion of entire networking projects — recommended for hub projects.
- **Organization Policy custom constraints** to deny
  `compute.networks.delete` / `compute.vpnGateways.delete` outside break-glass
  service accounts.
- `lifecycle { prevent_destroy = true }` is deliberately **not** baked into
  modules: it cannot be toggled by variable (Terraform limitation) and would
  make intentional teardown require code edits. Consumers wanting it can add
  it via an override in their root module fork of the invocation.

### OCI — IAM policy and tag-gated guards

OCI similarly has no per-resource lock. The framework's approach:

- The mandatory `managed_by = "terraform"` freeform tag (see
  `governance/tagging/`) supports IAM policies of the form
  *"deny group X to delete resources tagged managed_by='terraform' except
  group terraform-operators"*.
- Compartment-level IAM keeps `manage virtual-network-family` restricted to
  the automation principal and a small operator group.
- For organizations using defined tags, replicate the mandatory schema in a
  tag namespace and write policy conditions against it
  (`where target.resource.tag.governance.managed_by = 'terraform'`).

## Teardown procedure

Protected resources are deliberately destroy-resistant. The supported teardown
sequence is always:

1. Apply with the protection variable disabled
   (`delete_protection = false`, `enable_deletion_protection = false`,
   `enable_management_lock = false`).
2. Run `terraform destroy` (or remove the module block and apply).

Modules document this in their READMEs ("Destroy note"). CI pipelines should
treat a plan that disables a protection flag as a reviewable event.
