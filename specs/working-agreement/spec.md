# Working agreement

A capability of open-org-spec defining the bilateral contract artefact between two named scopes: what each owes the other, how they resolve conflicts, who arbitrates, and at what cadence they coordinate.

**Status:** Active (0.19.0)

## Purpose

The standard defines scopes — clusters, functions, projects — and their internal governance. It does not define how two scopes work together at their boundary. Without a shared artefact type for this, adopters invent ad-hoc documents, bury interface agreements inside one scope's spec, or rely on undocumented convention that new contributors must reconstruct from memory or meetings.

A working agreement is the stable contract at a scope boundary. It is distinct from a decision record (which captures a single resolved question at a point in time) and from the feedback inbox (which handles ongoing observations and bilateral nudges). Working agreements operate at a layer above both: they are the stable contract that decision records establish and that the feedback loop is held against.

## Pattern

### Location

Working agreements live at the adopter-declared `agreements/` path, typically at the repository root. Each agreement is a single file named using the `<scope-a>--<scope-b>.md` double-dash convention, where scope names are the canonical slugs of the two parties — matching their folder names or registered scope IDs. Alphabetical ordering of party names is recommended to avoid duplicate files for the same boundary.

Example: `agreements/engineering-function--product-function.md`

### Schema

Every working agreement file carries a header block and a required set of sections.

**Header block:**

```
# <Scope A> ↔ <Scope B> working agreement

**Status:** draft | agreed | under review | superseded
**Agreed:** YYYY-MM-DD  (omit if status is draft)
**Review date:** YYYY-MM-DD
**Parties:** <Scope A name (owner)> · <Scope B name (owner)>
**Arbitrator:** <name and role — the person who decides if parties cannot resolve>
```

**Required sections:**

| Section | What it contains |
|---|---|
| `## What <Scope A> owes <Scope B>` | Concrete commitments from Scope A — signals, artefacts, cadence, response time. Written as obligations, not intentions. |
| `## What <Scope B> owes <Scope A>` | Concrete commitments from Scope B — same shape. |
| `## Conflict resolution` | How the parties resolve a disagreement: who raises it, what conversation happens first, when the arbitrator is invoked. |
| `## Coordination cadence` | The standing operating rhythm: recurring touchpoints, async channels, escalation path. |

**Optional sections:**

| Section | When to use |
|---|---|
| `## Decisions referenced` | Links to the decisions that established the terms or resolved prior disputes. |
| `## Related working agreements` | Links to agreements at adjacent scope boundaries that interact with this one. |

### Lifecycle states

| State | Meaning |
|---|---|
| `draft` | Under discussion — not yet binding on either party |
| `agreed` | Both parties have acknowledged the agreement in writing |
| `under review` | One or both parties have triggered a review; current terms are advisory until re-agreed |
| `superseded` | Replaced by a newer agreement; file retained as history |

### Acknowledgement mechanism

Both parties must acknowledge the agreement before it moves to `agreed`. The acknowledgement is recorded inline in the file as a dated response from each party's owner — the same pattern as `feedback-inbox` entry resolution. An agreement signed by only one party remains `draft`.

A review is triggered when either party updates the status to `under review` and opens a feedback entry in the other party's inbox requesting a review session. The agreement returns to `agreed` only after both parties re-acknowledge the revised terms.

### Catalogue integration

When the `catalogue` capability is active, working agreements are indexed in the catalogue's output as an `agreements.yaml` file listing each agreement, its parties, its status, and its review date. Agreements with a past review date and `agreed` status are flagged as due for review and surface in the relevant scope owners' pending-feedback output.

## What is not prescribed

- **Whether every scope boundary has a working agreement.** Absence is valid. Simple, low-friction boundaries where expectations are unambiguous do not need a written agreement. A working agreement is warranted when a boundary produces repeated informal coordination or when a new contributor cannot infer the expected behaviour from scope specs alone.
- **The format of the obligations sections.** Each party writes their obligations in whatever form is most legible — bullet lists, tables, prose. The requirement is that obligations are concrete and checkable, not that they follow a specific format.
- **The length of the coordination cadence section.** A single standing meeting is a complete answer if it covers the coordination need. The section does not need to enumerate every possible touchpoint.
- **Whether arbitrator is a person or a role.** The arbitrator field names whoever has the authority to decide when parties cannot resolve — it may be a named person, a role title, or a governance mechanism. The requirement is that it is named, not that it takes a specific form.

## Rationale

**Scope specs describe how a scope works internally. Nothing describes how two scopes work together.** The standard defines scopes (clusters, functions, projects), their ownership structures, and their governance. What it does not define is the interface layer between scopes — the bilateral commitments that make coordination predictable. Without a shared artefact type for this, adopters invent ad-hoc documents, bury interface agreements in one scope's spec, or rely on undocumented convention. The same coordination problem is re-solved independently at every scope boundary.

**Decision records are not working agreements.** A decision record captures a single resolved question at a point in time: what was decided, why, and by whom. A working agreement is forward-looking and stable: it describes how two scopes will continue to operate at their boundary. The two artefact types are complementary, not redundant. A working agreement may reference the decisions that established it, but it is not itself a decision.

**Feedback inboxes handle bilateral nudges, not stable contracts.** The `feedback-inbox` capability supports ongoing observations and requests between contributors. Working agreements operate at a different layer: they are the stable contract that the feedback loop is held against. "You didn't provide the signal you agreed to" is a feedback entry. "We agree to exchange this signal on this cadence" is a working agreement.

**The interface problem compounds as organisations grow.** When an organisation has two scopes, undocumented interfaces are manageable. At ten scopes, undocumented interfaces become a coordination tax — every new contributor must reconstruct the interface conventions that experienced contributors hold in their heads. Written working agreements make this knowledge explicit, transferable, and auditable. They are the spec-driven organisation's answer to "how do these two parts work together?"

**One adopter has validated the pattern across multiple scope boundaries.** A real adoption has produced working agreements between functions, between a function and a cluster, and between a cluster and a shared service — all following the same bilateral structure. The pattern is generic and reusable. None of the content is adopter-specific; only the named scopes differ.

## Related

- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — bilateral nudge layer; working agreements are the stable contract above it
- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — decisions at scope; working agreements reference but do not replace decisions
- [`../people/spec.md`](../people/spec.md) — named owners of each party are required to acknowledge the agreement
- [`../tooling/catalogue/spec.md`](../tooling/catalogue/spec.md) — catalogue integration for agreement indexing and review-date alerting
