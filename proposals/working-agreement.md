---
change: working-agreement
status: draft
opened: 2026-06-24
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Working agreement capability

## Intent

Introduce `working-agreement` as a first-class artefact type in the standard: a bilateral contract between two named scopes that formalises what each owes the other, how they resolve conflicts, who arbitrates, and at what cadence they coordinate. Working agreements live at a dedicated location in the adopter's repository, follow a shared schema, carry a lifecycle (draft → agreed → under review → superseded), and reference the scopes they govern.

## Rationale

**Scope specs describe how a scope works internally. Nothing describes how two scopes work together.** The standard defines scopes (clusters, functions, projects), their ownership structures, and their governance. What it does not define is the interface layer between scopes — the bilateral commitments that make coordination predictable. Without a shared artefact type for this, adopters invent ad-hoc documents, bury interface agreements in one scope's spec, or rely on undocumented convention. The same coordination problem is re-solved independently at every scope boundary.

**Decision records are not working agreements.** A decision record captures a single resolved question at a point in time: what was decided, why, and by whom. A working agreement is forward-looking and stable: it describes how two scopes will continue to operate at their boundary. The two artefact types are complementary, not redundant. A working agreement may reference the decisions that established it, but it is not itself a decision.

**Feedback inboxes handle bilateral nudges, not stable contracts.** The `feedback-inbox` capability supports ongoing observations and requests between contributors. Working agreements operate at a different layer: they are the stable contract that the feedback loop is held against. "You didn't provide the signal you agreed to" is a feedback entry. "We agree to exchange this signal on this cadence" is a working agreement.

**The interface problem compounds as organisations grow.** When an organisation has two scopes, undocumented interfaces are manageable. At ten scopes, undocumented interfaces become a coordination tax — every new contributor must reconstruct the interface conventions that experienced contributors hold in their heads. Written working agreements make this knowledge explicit, transferable, and auditable. They are the spec-driven organisation's answer to "how do these two parts work together?"

**One adopter has validated the pattern across multiple scope boundaries.** A real adoption has produced working agreements between functions, between a function and a cluster, and between a cluster and a shared service — all following the same bilateral structure. The pattern is generic and reusable. None of the content is adopter-specific; only the named scopes differ.

## Delta

New artefact type and location convention added to the standard.

### Location

Working agreements live at the adopter-declared `agreements/` path (typically at the repo root). Each agreement is a single file named using the `<scope-a>--<scope-b>.md` double-dash convention, where scope names are the canonical slugs of the two parties (matching their folder names or registered scope IDs). Alphabetical ordering of party names is recommended to avoid duplicate files.

Example: `agreements/product-function--gtm-function.md`

### Schema

Every working agreement file carries the following sections:

**Required:**

```
# <Scope A> ↔ <Scope B> working agreement

**Status:** draft | agreed | under review | superseded
**Agreed:** YYYY-MM-DD  (omit if status is draft)
**Review date:** YYYY-MM-DD
**Parties:** <Scope A name (owner)> · <Scope B name (owner)>
**Arbitrator:** <name and role — the person who decides if parties cannot resolve>

## What <Scope A> owes <Scope B>
## What <Scope B> owes <Scope A>
## Conflict resolution
## Coordination cadence
```

**Optional:**

```
## Decisions referenced
## Related working agreements
```

### Lifecycle states

| State | Meaning |
|---|---|
| `draft` | Under discussion — not yet binding on either party |
| `agreed` | Both parties have acknowledged the agreement in writing (inline response or linked decision) |
| `under review` | One or both parties have triggered a review; current terms are advisory until re-agreed |
| `superseded` | Replaced by a newer agreement; file retained as history |

### Acknowledgement mechanism

Both parties must acknowledge the agreement before it moves to `agreed`. The acknowledgement is recorded inline in the file as a dated response from each party's owner — the same pattern as `feedback-inbox` entry resolution. An agreement signed by only one party remains `draft`.

### Catalogue integration

When the `catalogue` capability is active, working agreements are indexed in the catalogue's output as a `agreements.yaml` file listing each agreement, its parties, its status, and its review date. Agreements with a past review date and status `agreed` are flagged as due for review.

## Acceptance scenarios

### Two functions establish a working agreement

Given two functions with named owners
When their boundary produces repeated coordination questions that are resolved informally
Then one party drafts `agreements/<function-a>--<function-b>.md` with status `draft`
And both owners add an inline acknowledgement
And the agreement advances to status `agreed`
And the catalogue indexes it with the review date

### Working agreement referenced from a scope spec

Given a working agreement in status `agreed`
When either scope spec describes the relationship with the other party
Then the spec carries a `Related` link pointing to the working agreement
And readers arriving at either spec can navigate to the bilateral contract

### Review triggered after org change

Given a working agreement in status `agreed` with a review date of YYYY-MM-DD
When that date passes or a structural change affects one of the parties
Then either party updates the status to `under review`
And a feedback entry is opened in the other party's inbox requesting a review session
And the agreement is re-negotiated and re-acknowledged before returning to `agreed`

### Catalogue surfaces overdue reviews

Given the catalogue capability is active
When `/catalogue` runs and finds an `agreed` working agreement whose `review_date` is past
Then `agreements.yaml` flags the agreement as overdue
And the entry surfaces in the relevant scope owners' `/my-pending-feedback` output

### Arbitrator invoked

Given a working agreement in status `agreed` naming an arbitrator
When the two parties disagree on a boundary question and cannot resolve through the coordination cadence
Then either party opens a decision record in their scope's `decisions/` folder describing the dispute
And the arbitrator is named as Decider
And the decision record references the working agreement

## Related

- `specs/feedback-inbox/spec.md` — bilateral nudge layer; working agreements are the stable contract above it
- `specs/governance-at-scope/spec.md` — decisions at scope; working agreements reference but do not replace decisions
- `specs/people/spec.md` — named owners of each party are required to acknowledge the agreement
- `specs/tooling/catalogue/spec.md` — catalogue integration for agreement indexing and review-date alerting
