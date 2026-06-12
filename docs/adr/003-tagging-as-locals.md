# ADR 003 — Tagging as Self-Contained Locals; governance/tagging Is Docs-Only

**Status:** Accepted
**Date:** 2026-06-11

## Context

Every resource in the framework must carry a mandatory tag set (`environment`,
`owner`, `cost_center`, `managed_by`, `module_source`). The obvious DRY
solution is a shared tagging module — `module "tags" { source =
"../../governance/tagging" }` — that every leaf module calls.

That design has real costs:

- It violates ADR 001: every module would depend on the tagging module, making
  it the framework's single coupling point. A breaking change there forces a
  release of all 48 modules.
- Terraform module calls for pure data transformation add graph nodes, plan
  noise, and an extra hop when debugging "where did this tag come from."
- Consumers vendoring a single module (a supported adoption path) would have to
  vendor the tagging module too — or patch it out.

## Decision

1. **`governance/tagging/` is documentation and a reference implementation
   only.** It contains no callable Terraform. No leaf module may source it.
2. **Each leaf module embeds its own copy** of the standard locals block:

   ```hcl
   locals {
     mandatory_tags = {
       environment   = var.environment
       owner         = var.owner
       cost_center   = var.cost_center
       managed_by    = "terraform"
       module_source = "<module-path-relative-to-repo-root>"
     }
     all_tags = merge(var.additional_tags, local.mandatory_tags)
   }
   ```

3. All taggable resources reference `local.all_tags` — inline tag maps are
   prohibited. Per-resource additions (like AWS `Name`) merge *on top of*
   `all_tags` at the resource.
4. Merge order is fixed: mandatory tags override `additional_tags` on
   collision, so consumers cannot silently overwrite governance keys.
5. Cloud dialects are local concerns: GCP modules lowercase keys/values and
   reshape `module_source` (labels reject `/`); OCI modules emit
   `freeform_tags`; untaggable resources (Azure peerings, GCP classic firewall
   rules, etc.) document the gap and rely on naming.

## Consequences

- ~15 duplicated lines per module — trivially reviewable, and `module_source`
  *must* differ per module anyway, so a shared module would still need
  per-module input.
- Drift between copies is possible. Mitigations: the block is small and
  mechanical; `governance/tagging/README.md` is the authoritative spec; a CI
  grep for `mandatory_tags` structure keeps copies honest.
- Schema changes (adding a mandatory tag) touch all modules. This is accepted:
  such changes are rare, mechanical, and in a coupled design would *also*
  require releasing every module — with less visibility.
- Zero runtime coupling: any module can be vendored, forked, or pinned alone.
