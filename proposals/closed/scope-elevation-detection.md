---
change: scope-elevation-detection
status: applied
opened: 2026-06-07
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: scope-elevation detection

## Intent

A scope-coherence scanner under `governance-at-scope` tooling that reads the catalogue and detects two patterns:

1. **Content-location mismatch** — a spec recorded at a narrow scope whose content suggests cross-scope or broader applicability (e.g. a risk at `clusters/A/risks/` that mentions multiple clusters or org-wide systems).
2. **Cross-scope duplicates** — the same concept recorded independently at different scopes (e.g. the same regulatory risk filed separately in two clusters and at the project level).

When detected, the scanner files a `[scope-elevation]` entry — a new `feedback-inbox` type — routed to whoever owns the higher scope. The contributor's work is never blocked; the placement question is resolved separately by the scope owners.

Runs post-hoc on a schedule alongside the existing `conformance` agent.

## Rationale

**Contributors focus on their scope and should not have to think about scope placement.** Asking contributors to reason about whether their artefact belongs at a higher scope adds governance overhead that competes with the actual work they are doing. The right division: contributors record things correctly at their scope; a post-hoc scanner determines if the placement is optimal.

**The catalogue already provides the cross-scope view.** The `catalogue` capability walks all governed spec paths and produces structured output that includes scope, owner, and artefact type for every spec in the repo. Scope-coherence comparison is diffable from that output without additional crawling — the scanner reads the catalogue rather than traversing the repo itself.

**Two distinct signals cover the main failure modes.** Content-location mismatch catches artefacts that were placed at the wrong scope at creation time (author recorded a cross-org risk in a single cluster). Cross-scope duplicates catches parallel work where two contributors independently solved the same problem at different scopes without knowing about each other. Both signals are detectable from catalogue metadata and artefact content without requiring contributor action.

**Routing to the higher-scope owner, not the contributor, respects contribution.** The contributor who filed the artefact did the right thing — they recorded something real and placed it at a scope they understood. Routing the scope question to them would create retrospective burden. Routing to the higher-scope owner is the right call: they have the context to decide whether elevation, consolidation, or cross-reference is the correct resolution.

## Delta

- New: `specs/governance-at-scope/tools/scope-elevation/spec.md` — the scanner tool spec
- Update: `specs/feedback-inbox/spec.md` — add `[scope-elevation]` to the entry-type vocabulary with routing convention (to higher-scope owner, not the originating contributor)

## Acceptance scenarios

### Content-location mismatch detected

Given a risk spec at `clusters/A/risks/2026-06-01-vendor-lock-in.md` whose content describes exposure affecting all clusters
When the scope-elevation scanner runs
Then it files a `[scope-elevation]` entry to the repo-wide governance owner: "risk at clusters/A describes org-wide exposure — consider elevating to decisions/ or a cross-scope risk register"

### Cross-scope duplicate detected

Given risk specs at `clusters/A/risks/`, `clusters/B/risks/`, and `projects/X/risks/` all describing the same regulatory compliance gap
When the scanner runs
Then it files a `[scope-elevation]` entry to the governance owner naming all three instances: "three risk records describe the same compliance gap at different scopes — consider consolidating at the highest applicable scope"

### Correctly scoped artefact not flagged

Given a risk at `clusters/A/risks/` that describes an issue specific to cluster A's systems with no cross-cluster language
When the scanner runs
Then no scope-elevation entry is filed

### Contributor is not interrupted

Given a contributor is mid-session creating a risk spec at `clusters/A/risks/`
When the scope-elevation scanner runs (on schedule, not in-session)
Then the contributor's session is unaffected — the entry is filed to the governance owner asynchronously

### Scope-elevation entry routes to higher-scope owner

Given a `[scope-elevation]` entry is filed
When the higher-scope owner reads it
Then they respond with one of: elevate (move the artefact), consolidate (merge instances), cross-reference (keep at scope but link), or decline with rationale

## Decision authority

Javier Fernandez (Standard author). Motivated by reference-implementation case where risks recorded at cross-cluster scope had possible earlier instances at cluster and project scope with no detection mechanism. 2026-06-07.
