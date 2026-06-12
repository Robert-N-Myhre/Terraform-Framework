# ADR 001 — Independent Invocability as the Primary Design Constraint

**Status:** Accepted
**Date:** 2026-06-11

## Context

This framework serves three audiences with very different consumption patterns:

1. **Individual practitioners** deploying one capability at a time for labs and
   portfolio work — often into pre-existing or throwaway environments.
2. **Engineering teams** adopting a *subset* of modules as internal standards,
   alongside existing in-house modules they will not replace.
3. **Enterprise evaluators** scoring individual modules as reference
   implementations, frequently without permission to stand up anything beyond
   the module under review.

Common framework designs fail these audiences: "landing zone" frameworks where
the firewall module imports the network module force consumers to adopt
everything to use anything; shared "base" modules create version-coupling where
upgrading one capability forces re-planning all of them.

## Decision

**Every leaf module is independently invocable.** Concretely:

- A consumer can call any single leaf module in isolation and deploy exactly
  that capability and nothing else.
- **No leaf module may `source`, call, or depend on any other module in this
  framework.** This is a hard prohibition, enforceable by review and by a
  trivial CI grep for `source` lines pointing inside `modules/`.
- All cross-capability references travel as **plain values** (IDs, OCIDs,
  self-links, names) through variables. A firewall module takes `vpc_id`,
  never `module.core_network`.
- Composition happens only in consumer root modules and in `examples/`.

Every other design goal — DRY-ness, shared interfaces, convenience wrappers —
is subordinate to this constraint.

## Consequences

**Positive**

- Any module is adoptable with zero framework lock-in; an existing VPC, VNet,
  VCN, or project is a first-class deployment target.
- Blast radius of a change is one module. Versioning, testing, and review scope
  stay small.
- Evaluation cost is one `terraform plan` against existing infrastructure.

**Negative (accepted)**

- Deliberate duplication: tagging/naming locals are copied into every module
  (see ADR 003), and the governance variables repeat 48 times. We accept ~40
  lines of boilerplate per module as the price of zero coupling.
- Consumers own the wiring: composing modules means passing outputs to inputs
  by hand. The composition examples (`core-network-with-*`) document the
  pattern.
- No framework-level orchestration (e.g., "deploy a full landing zone" in one
  call). Consumers wanting that build their own thin wrapper root module —
  outside this repo.

## Compliance check

`grep -r "source" modules/ | grep "\.\./"` must return nothing. Any PR
introducing an inter-module source fails review.
