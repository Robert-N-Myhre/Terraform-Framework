# ADR 005 — State Management Pattern: Backends Belong in Examples, Not Modules

**Status:** Accepted
**Date:** 2026-06-11

## Context

Terraform evaluates `backend` blocks only in the **root** module; a backend
block inside a child module is at best dead weight and at worst misleading.
Beyond the mechanical fact, state topology is an organizational decision:
how state is split (per module? per environment? per team?), where it lives,
who can read it, and how it is locked are questions only the consumer can
answer — a lab user wants local state; an enterprise wants per-environment
remote state with locking and SSE.

Frameworks that ship opinionated backend config in modules force every
consumer to override or patch it, and frameworks that ship none leave new
users with silent local-state foot-guns in shared environments.

## Decision

1. **No leaf module contains any backend configuration.** Modules are pure
   capability definitions; state is the consumer's responsibility.
2. **Every example ships a `backend.tf` containing a fully commented,
   cloud-appropriate placeholder** showing the recommended pattern:
   - AWS: `s3` backend + DynamoDB lock table
   - Azure: `azurerm` backend (Blob Storage; native blob-lease locking)
   - GCP: `gcs` backend (native locking)
   - OCI: `s3` backend against the Object Storage S3-compatibility endpoint
3. **`docs/state-management.md`** carries the full guidance: workspace
   strategy, state isolation per module/domain, bootstrap steps, and the
   local-to-remote migration path.

## Consequences

- Examples run immediately with local state (zero setup for labs) while
  showing exactly one uncomment-and-fill step to production-grade state.
- Consumers can adopt any topology: one state per module invocation
  (recommended — matches the independent-invocability model), per domain, or
  per environment, without fighting framework opinions.
- The framework cannot *enforce* remote state. Mitigation: every example
  README repeats the recommendation, and `docs/state-management.md` documents
  the risks of shared local state.
- The commented placeholders must be kept current with backend syntax changes
  (e.g., the S3 backend's `endpoints` block replacing `endpoint`), tracked
  like any other code in review.
