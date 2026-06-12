# ADR 002 — Convention-Based Shared Interface vs. Enforced Coupling

**Status:** Accepted
**Date:** 2026-06-11

## Context

Consumers working across clouds want predictability: calling
`aws/firewall/security-groups` and `azure/firewall/nsgs` should *feel* the same
— same governance variables, similar input shapes, similar output names —
without forcing the clouds through a lowest-common-denominator abstraction.

Two ways to get a shared interface:

1. **Enforced coupling** — a shared "interface module" or type library each
   cloud module imports; or a single multi-cloud module with a `cloud`
   switch.
2. **Convention** — each cloud module is written natively, but variable naming
   and output contracts follow a documented per-domain convention.

Option 1 violates ADR 001 (modules would depend on a shared artifact, and its
version becomes a coupling point) and historically produces abstractions that
fit no cloud well — Azure NSG association models, GCP tag-targeted global
rules, and OCI's dual security-list/NSG system simply do not share a schema.

## Decision

**Convention over coupling.** The interface is enforced by this documentation
and by code review — never by code references between modules.

### Universal contract (all modules)

Inputs: `prefix`, `environment`, `owner`, `cost_center`,
`additional_tags (map(string), {})`, `name_suffix ("01")`.

### Per-domain output contracts

| Domain | Outputs (where the concept exists) |
|--------|-------------------------------------|
| core-network | `network_id`, `network_cidr`, `subnet_ids` (map), `route_table_ids`, `nat_ids`, `flow_log_id` |
| firewall | `firewall_ids` (map), `rule_ids` (map) |
| dns | `zone_ids`, `zone_names`, `record_ids` (+ resolver endpoint outputs) |
| transit | `hub_id` (hubs), `connection_ids` (peerings), `attachment_ids`, `route_table_ids` |
| hybrid-connectivity | `gateway_id`, `connection_ids`, tunnel/circuit metadata |
| load-balancer | `lb_id`, `lb_dns_name`/`lb_address`, `listener_ids`, `backend_ids` |

### Parity rule

Where a cloud has no equivalent concept, the module still exposes the output
with a documented null/empty value (e.g., GCP `network_cidr = null`,
`flow_log_id = null`) so consumers can write cloud-agnostic plumbing without
conditionals on output *existence*.

### Native-first rule

Inside the contract, each module models its cloud natively: AWS SG-to-SG
references, Azure ASG references, GCP tag targeting, OCI NSG references all
appear in their natural form. The contract constrains *names and shapes of the
seams*, not the semantics inside them.

## Consequences

- Cross-cloud consumers get muscle-memory portability of the interface while
  retaining full native capability.
- Divergent behavior (statefulness, association models, tunnel counts) is
  surfaced explicitly via "Cross-cloud divergence" sections in every module
  README plus inline comments in `main.tf` — the convention makes differences
  *visible* rather than papering over them.
- The contract can drift without a compiler to catch it. Mitigation: this ADR
  is the source of truth, and PR review includes a contract checklist
  (CONTRIBUTING.md).
- New domains require a contract amendment here before the first module lands.

## Amendment — 2026-06-12: hub-attached gateways and NVA routing

1. **Hybrid modules may offer an `attachment_type` switch** (`vnet`/`vhub` on
   Azure, mirroring AWS's `vgw`/`tgw`) that relocates the gateway into a
   transit hub supplied **by ID**. The output contract is unchanged:
   `gateway_id` and `connection_ids` refer to whichever gateway/connection
   flavor the mode created. This preserves ADR 001 — the hub is never a module
   reference.
2. **Transit modules may expose cloud-specific NVA-steering extras** beyond the
   base contract (Azure vWAN: `hub_route_ids`, `bgp_connection_ids`). Extra
   outputs are permitted by the parity rule; other clouds need no null
   counterparts for them.
3. Azure vWAN **routing intent is intentionally unmodeled** while the framework
   targets third-party NVA-in-spoke firewalls — it only supports in-hub
   next-hops. Revisit if an integrated-hub-NVA or Azure Firewall vhub
   deployment mode is added.
