# Terraform Multi-Cloud Networking Framework

A modular Terraform framework covering the six core cloud-networking domains —
**core network fabric, firewall & security, DNS, transit, hybrid connectivity,
and load balancing** — implemented natively for **AWS, Azure, GCP, and OCI**.

## The one rule that defines this framework

> **Every leaf module is independently invocable.** You can call any single
> module in isolation — against existing infrastructure, with zero dependency
> on any other module in this repo — and deploy exactly that capability and
> nothing else.

No module sources another module. Cross-capability references travel as plain
values (`vpc_id`, `vcn_id`, self-links, OCIDs) through variables. Composition
happens in *your* root module — see [ADR 001](docs/adr/001-independent-invocability.md).

## Repo map

```
modules/
  aws/    core-network | firewall/{security-groups,nacls,network-firewall}
          dns/{private-zones,resolver} | transit/{peering,transit-gateway}
          hybrid-connectivity/{vpn,direct-connect} | load-balancer/{alb,nlb}
  azure/  core-network | firewall/{nsgs,asgs,azure-firewall}
          dns/{private-zones,resolver} | transit/{peering,vwan}
          hybrid-connectivity/{vpn,expressroute} | load-balancer/{load-balancer,application-gateway}
  gcp/    core-network | firewall/{vpc-firewall-rules,hierarchical-firewall,cloud-armor}
          dns/{private-zones,dns-policy} | transit/{peering,network-connectivity-center}
          hybrid-connectivity/{cloud-vpn,cloud-interconnect} | load-balancer/{internal,external}
  oci/    core-network | firewall/{security-lists,nsgs,network-firewall}
          dns/{private-views,resolver} | transit/{lpg,drg}
          hybrid-connectivity/{ipsec-vpn,fastconnect} | load-balancer/{load-balancer,network-load-balancer}
examples/   4 per cloud: one isolated module, core-network-only, dns-only, one composition
            + azure/vwan-with-nva-firewall: vWAN steered through a third-party NVA (VM-Series pattern)
governance/ tagging | naming | resource-locks   (documentation only — never callable)
docs/       adr/001-005 | state-management.md
```

48 leaf modules. Each contains `main.tf`, `variables.tf`, `outputs.tf`,
`versions.tf` (pinned `~>` provider ranges with tested-version comments), and a
terraform-docs-compatible `README.md` with a standalone usage example.

## Quick start per cloud

Each command sequence deploys exactly one module. Replace the placeholder IDs.

**AWS** — security groups into an existing VPC:
```bash
cd examples/aws/security-groups-only
terraform init && terraform apply -var "vpc_id=vpc-0abc123def456789a"
```

**Azure** — NSGs into an existing resource group:
```bash
cd examples/azure/nsgs-only
terraform init && terraform apply -var "subscription_id=..." -var "resource_group_name=rg-lab"
```

**GCP** — firewall rules onto an existing network:
```bash
cd examples/gcp/vpc-firewall-rules-only
terraform init && terraform apply -var "project_id=my-project" -var "network_name=my-vpc"
```

**OCI** — security lists into an existing VCN:
```bash
cd examples/oci/security-lists-only
terraform init && terraform apply -var "compartment_id=ocid1...." -var "vcn_id=ocid1...."
```

Greenfield instead? Use the `core-network-only` example for each cloud; the
`core-network-with-*` examples then show the composition pattern (outputs wired
to inputs in the example root).

Building a vWAN with a third-party firewall (Palo Alto VM-Series style)? See
`examples/azure/vwan-with-nva-firewall/` — hub route tables + connection static
routes steering spoke and branch traffic through an NVA services VNet, with the
hybrid modules' `attachment_type = "vhub"` for hub-resident VPN/ER gateways.

## Consistent interface, native implementations

Within each domain, all four clouds share variable naming and an output
contract **by convention** ([ADR 002](docs/adr/002-convention-based-interface.md)):
every module takes `prefix`, `environment`, `owner`, `cost_center`,
`additional_tags`, `name_suffix`; every core-network module emits `network_id`,
`subnet_ids`, `nat_ids`, ...; every load balancer emits `lb_id`, `listener_ids`,
`backend_ids`. Where a cloud lacks a concept, the output exists with a
documented null (GCP `network_cidr`) so cross-cloud plumbing needs no
existence checks.

Inside that contract, each module is **fully native** — AWS SG-to-SG
references, Azure ASGs, GCP tag targeting, OCI dual security-list/NSG models —
with the behavioral differences called out in a "Cross-cloud divergence"
section in every README and inline in `main.tf`.

## Governance

- **Tagging** — every module embeds the mandatory tag locals
  (`environment`, `owner`, `cost_center`, `managed_by`, `module_source`);
  mandatory keys win over `additional_tags`. Spec: [governance/tagging](governance/tagging/README.md), rationale: [ADR 003](docs/adr/003-tagging-as-locals.md).
- **Naming** — `{prefix}-{cloud}-{environment}-{resource-type}-{suffix}` via
  per-module locals, no hardcoded names. Spec: [governance/naming](governance/naming/README.md), rationale: [ADR 004](docs/adr/004-naming-convention.md).
- **Resource locks** — deletion protection on by default wherever the provider
  supports it (AWS `delete_protection`, Azure `CanNotDelete` locks), with
  documented IAM/policy patterns for GCP and OCI. Spec: [governance/resource-locks](governance/resource-locks/README.md).

The `governance/` directories are **documentation only** — they are not
callable modules and nothing sources them.

## State

Leaf modules carry **no backend configuration** — state is yours
([ADR 005](docs/adr/005-state-management-pattern.md)). Every example ships a
commented `backend.tf` with the cloud-appropriate remote pattern
(S3+DynamoDB, Azure Blob, GCS, OCI Object Storage S3-compat). Full guidance —
isolation strategy, workspaces, local-to-remote migration — in
[docs/state-management.md](docs/state-management.md).

## Audience guide

**Lab / portfolio users** — pick one module, run its `*-only` example with
local state, destroy when done. Watch the "Destroy note" in module READMEs:
deletion protection defaults to **on**; flip the variable and apply before
destroying. The examples set lab-friendly defaults where it matters.

**Engineering teams** — adopt modules selectively as internal standards:
pin by tag (`source = "github.com/you/repo//modules/aws/core-network?ref=v1.2.0"`),
wire them to your existing networks by ID, keep one state per module
invocation, and layer your org's policy engine over the tagging schema. You do
not need to adopt any module you didn't choose — there is no shared base to
drag in.

**Enterprise evaluators** — each module is a self-contained reference
implementation: review `main.tf` for the native patterns, `versions.tf` for the
pinning discipline, and the README's divergence notes for the multi-cloud
gotchas. A single `terraform plan` against an existing network evaluates a
module end to end without touching anything else.

## Requirements

- Terraform >= 1.5.0
- Provider credentials for the cloud(s) you target
- Providers (pinned per module): hashicorp/aws `~> 5.0`, hashicorp/azurerm
  `~> 3.80`, hashicorp/google `~> 5.0`, oracle/oci `~> 5.0`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — including the hard rules (no
inter-module sourcing, no inline tags, no hardcoded names/regions/IDs) and the
interface-contract checklist.

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md). Please use GitHub's
private vulnerability reporting (the repository's **Security** tab) rather than a
public issue.

## License

Licensed under the [Apache License 2.0](LICENSE).
