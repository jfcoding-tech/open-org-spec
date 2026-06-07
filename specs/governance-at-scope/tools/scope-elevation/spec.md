# Scope-elevation

**Owner:** Javier Fernandez
**Status:** Active

A governance maintenance tool of the [`governance-at-scope`](../../spec.md) capability.
Reads the catalogue and detects artefacts that may be placed at the wrong scope —
either because their content is broader than their location, or because the same
concept has been recorded independently at multiple scopes. Routes a `[scope-elevation]`
feedback entry to the higher-scope owner when a candidate is found.

## Purpose

Contributors work within their scope and record artefacts there. That is the right
posture — the alternative (asking contributors to reason about scope elevation before
creating anything) adds governance overhead that competes with the actual work.
But the result is that some artefacts end up at a narrower scope than their content
warrants, and identical or overlapping artefacts accumulate at different scopes without
anyone noticing.

`scope-elevation` closes that gap post-hoc. It does not block contributors; it surfaces
candidates to the people who have the cross-scope context to decide what to do.

## Inputs (extension points)

- **Catalogue path** — where the adopter's catalogue lives (required; the catalogue
  is the primary data source; the scanner does not walk the repo itself)
- **Governed scope paths** — which top-level folders define named scopes
  (e.g. `clusters/`, `projects/`, `ai-factory/`, `decisions/`)
- **Higher-scope routing** — how each scope maps to its parent scope and feedback inbox
- **Scope keywords** — optional list of terms that signal cross-scope content
  (e.g. "all clusters", "org-wide", "cross-cluster", "all teams") — used to tune
  the content-location mismatch signal

## Detection signals

### Signal 1 — Content-location mismatch

A spec is filed at scope `A` but its content suggests broader applicability.

**How detected:** for each spec in the catalogue, compare the content's apparent scope
(keywords, named scopes mentioned, breadth of impact described) against the spec's
location scope (the folder it lives in). Flag when content breadth > location scope.

Indicators that raise this signal:
- The spec mentions scopes outside its own folder (e.g. names other clusters)
- The spec uses cross-scope keywords from the adopter-declared list
- The spec describes a risk, decision, or pattern whose impact is not bounded to the
  filing scope

**Not flagged:** a spec that mentions another scope as a *dependency* or *related link*
without claiming to govern or describe that scope.

### Signal 2 — Cross-scope duplicates

The same concept is recorded independently at two or more scopes.

**How detected:** across all specs of the same artefact type (e.g. all risk records,
all decisions), compare titles and key content across scopes. Flag pairs or groups
with high semantic similarity filed at different scopes.

Indicators that raise this signal:
- Near-identical titles at two or more scopes
- Same regulatory body, system, or named risk described across separate risk records
- Decision records resolving the same question at different scopes

**Not flagged:** related artefacts that are explicitly cross-referenced to each other
(a scope-level decision that cites a repo-wide decision it implements is not a duplicate
— it is a deliberate cascade).

## Routing

When a candidate is found:

1. Determine the higher scope (the nearest ancestor scope that contains all affected
   scopes, or the repo-wide governance scope if no single cluster ancestor applies).
2. Find the higher scope's feedback inbox (from the adopter-declared routing table).
3. File a `[scope-elevation]` entry addressed to the higher scope's owner:

**Content-location mismatch entry:**
```
## YYYY-MM-DD | scope-elevation agent → <higher-scope-owner> [scope-elevation]

`<path/to/spec.md>` is filed under `<scope A>` but its content describes
<brief summary of cross-scope signal>. Consider: elevating to `<higher scope>`,
adding a cross-reference from the higher scope, or confirming it belongs at
`<scope A>` with a note explaining why.
```

**Cross-scope duplicate entry:**
```
## YYYY-MM-DD | scope-elevation agent → <higher-scope-owner> [scope-elevation]

Two or more records describe the same concept at different scopes:
- `<path/to/spec-A.md>` at `<scope A>`
- `<path/to/spec-B.md>` at `<scope B>`

Consider: consolidating at `<higher scope>`, designating one as canonical and
cross-referencing from the other, or confirming they are distinct with an explicit
note on the distinction.
```

The contributor who filed the original artefact is **not** notified and is not
expected to act. The scope question is the higher-scope owner's to resolve.

## Execution optimisations

**Catalogue fast-path.** When the catalogue is available and fresh (< 25 hours old),
read it directly. The catalogue holds scope, owner, title, and file path for every
governed spec — sufficient for both signals without re-walking the repo. When the
catalogue is stale or absent, fall back to direct repo traversal.

**Dedup window.** Do not re-file a `[scope-elevation]` entry for the same artefact
within the adopter-declared dedup window (default 30 days). Read the higher-scope
inbox before filing to check for an existing open entry for the same path.

**Resolved entries are not re-raised.** When the higher-scope owner has resolved a
prior `[scope-elevation]` entry for an artefact (prefixed `[resolved]`), do not
re-raise the same artefact unless its content changes materially.

## Extension points

- Catalogue path
- Governed scope paths and parent-scope routing
- Scope keywords (content-location mismatch tuning)
- Dedup window (default 30 days)
- Artefact types to scan (default: all; adopter may restrict to `risks`, `decisions`,
  or other named types)
- Similarity threshold for cross-scope duplicate detection

## What scope-elevation does not do

- **Does not move artefacts.** It files entries; the scope owners decide and act.
- **Does not block contributors.** It runs post-hoc on a schedule; contributors are
  never interrupted.
- **Does not route to the filing contributor.** The contributor did the right thing —
  they recorded something at a scope they understood. The placement question goes to
  whoever has the higher-scope view.
- **Does not compare content semantics deeply.** It uses title similarity and keyword
  detection, not full NLP comparison. Missed duplicates are accepted false negatives;
  the signal is a heuristic, not a guarantee.

## Rationale

**Contributors focus on their scope and should not have to think about scope placement.** Asking contributors to reason about whether their artefact belongs at a higher scope adds governance overhead that competes with the actual work. The right division: contributors record things at the scope they understand; a post-hoc scanner determines if the placement is optimal.

**The catalogue already provides the cross-scope view.** The `catalogue` capability walks all governed spec paths and produces structured output including scope, owner, and artefact type for every spec. Scope-coherence comparison is diffable from that output without additional crawling — the scanner reads the catalogue rather than traversing the repo itself.

**Two distinct signals cover the main failure modes.** Content-location mismatch catches artefacts placed at the wrong scope at creation time. Cross-scope duplicates catches parallel work where contributors independently solved the same problem at different scopes without knowing about each other. Both are detectable from catalogue metadata and artefact content without contributor action.

**Routing to the higher-scope owner, not the contributor, respects contribution.** The contributor who filed the artefact did the right thing — they recorded something real at a scope they understood. Routing the scope question to them creates retrospective burden. The higher-scope owner has the context to decide whether elevation, consolidation, or cross-reference is the correct resolution.

## Related

- [`../../spec.md`](../../spec.md) — governance-at-scope capability; this tool enforces
  the scope-placement discipline it declares.
- [`../decision-escalation/spec.md`](../decision-escalation/spec.md) — companion
  governance maintenance tool; escalates stale decisions rather than misplaced artefacts.
- [`../../../feedback-inbox/spec.md`](../../../feedback-inbox/spec.md) — entry format
  and `[scope-elevation]` entry type.
- [`../../../tooling/catalogue/spec.md`](../../../tooling/catalogue/spec.md) — primary
  data source; the catalogue fast-path depends on this capability being active.
