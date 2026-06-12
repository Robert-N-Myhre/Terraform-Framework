# Contributing

Thanks for improving the framework. Contributions are held to the same
constraints the existing modules follow — most of them are *hard rules*, not
preferences.

## Hard rules (PRs violating these are rejected)

1. **No inter-module sourcing.** No `module` block inside `modules/**` may
   source another module in this repository — or anywhere else. Leaf modules
   are self-contained ([ADR 001](docs/adr/001-independent-invocability.md)).
   Check: `grep -rE 'source\s*=' modules/ | grep -v 'required_providers'`
   must show no module sources.
2. **No backend configuration in modules.** Backends live only in
   `examples/**/backend.tf`, commented ([ADR 005](docs/adr/005-state-management-pattern.md)).
3. **Tagging via the standard locals only.** Every module embeds the
   `mandatory_tags` / `all_tags` block with its own `module_source`; every
   taggable resource references `local.all_tags`; no inline tag literals
   ([ADR 003](docs/adr/003-tagging-as-locals.md)).
4. **Naming via the convention only.** All names derive from
   `{prefix}-{cloud}-{environment}-{resource-type}-{suffix}` locals; no
   hardcoded names ([ADR 004](docs/adr/004-naming-convention.md)). Cloud-mandated
   exact names (e.g., `GatewaySubnet`) are the only exception and must be
   documented.
5. **No hardcoded regions, account IDs, subscription IDs, project IDs, or
   OCIDs.** All come in as variables with descriptions.
6. **Every variable** has `type` and `description`; **every output** has
   `description`; sensitive values are marked `sensitive = true`.
7. **`for_each` over `count`** for all multi-instance resources (`count` is
   acceptable only for boolean 0/1 toggles).
8. **versions.tf** in every module: `required_version`, `required_providers`
   with `source` and a `~>` range (never unpinned, never `=`), plus the
   comment block documenting tested version, breaking-change boundary, and
   range rationale.
9. **`moved` blocks** whenever a change relocates resource addresses, so
   consumers upgrade without state surgery.

## Interface contract checklist (per domain)

Before adding or changing a module, confirm against
[ADR 002](docs/adr/002-convention-based-interface.md):

- [ ] Governance inputs present: `prefix`, `environment`, `owner`,
      `cost_center`, `additional_tags`, `name_suffix`.
- [ ] Domain outputs match the contract table (`network_id`, `firewall_ids`,
      `zone_ids`, `hub_id`/`connection_ids`, `gateway_id`, `lb_id`, ...).
- [ ] Missing-concept outputs exist with documented null/empty values.
- [ ] "Cross-cloud divergence" section in the README + inline comment in
      `main.tf` where the cloud's model differs materially from the others.

## Module file layout

Every leaf module: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`,
`README.md` (terraform-docs-compatible: requirements, providers, inputs table,
outputs table, standalone usage example with realistic values).

Every example: `main.tf`, `variables.tf`, `outputs.tf`, `backend.tf`
(commented placeholder), `README.md` (what deploys, required inputs, how to
run).

## Workflow

1. Branch from `main`; one module or one concern per PR.
2. `terraform fmt -recursive` and `terraform validate` in each touched module
   (validate requires a scratch `terraform init` — no credentials needed).
3. Recommended local checks: `tflint` and `terraform-docs markdown table`
   to regenerate README tables.
4. PR description states which audiences are affected (lab / team / enterprise)
   and whether the change is breaking for module consumers. Breaking changes
   need a `moved` block or a documented migration note.

## Adding a new domain or cloud

Open an issue first. A new domain requires amending the interface contract in
ADR 002 *before* the first module lands; a new cloud requires the full
six-domain decomposition plan and the same per-module discipline as the
existing four.
