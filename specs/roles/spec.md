# Roles

A capability of open-org-spec defining how individual accountabilities are specified within a scope: what a role exists to do, what it owns, how it works with peers, and what success looks like.

**Status:** Active (0.19.0)

## Purpose

A spec-driven repository names who holds roles at each scope — but naming is not the same as specifying. `people.md` answers *who is here*; a role spec answers *what this position is accountable for and why*. Without a shared pattern for this, organisations produce prose job descriptions that tools cannot parse, embed accountability in narrative specs that mix structural and content concerns, or rely on informal understanding that exists only in people's heads. All three fail when the org grows, when roles change hands, or when accountability gaps need to be surfaced systematically.

## Pattern

### Role spec schema

A role spec is a markdown file with YAML frontmatter and required sections.

**Required frontmatter fields:**

```yaml
role: <title of the role>
owner: <name of the person who owns this spec — typically the manager>
incumbent: <name of the current holder, or "vacant" or "TBD">
status: <draft | agreed | active | under-review>
reports_to: <role title and name of the person this role reports to>
effective: <YYYY-MM or YYYY-MM-DD — when this version took effect>
```

**Required sections:**

| Section | What it contains |
|---|---|
| `## The Role` | Two to four paragraphs: why this role exists, where it sits in the accountability structure, what it does not own (the boundary statement). |
| `## What You Will Own` | Named accountability items. Each item has a bold heading and a paragraph explaining the accountability, the outcome, and the failure mode it replaces or prevents. |
| `## How You Work With Your Peers` | Bilateral table. One row per peer. Columns: Peer \| What they bring you \| What you owe them. Peer is role title, not name. |
| `## What Success Looks Like` | Table of measurable outcomes. Columns: Milestone / KPI \| Target \| By when \| Shared with. Success criteria must be outcome-linked — not activity counts or delivery milestones alone. |
| `## What You Bring` | Bulleted list of competencies and dispositions the role requires. Written in second person ("you…"). No competency without a rationale sentence. |

**Optional sections:**

| Section | When to use |
|---|---|
| `## Pending` | Open questions or items that must be resolved before the spec can move to `agreed` or `active`. Each item names an owner and what is blocking it. Removed when all items are resolved. |
| `## Related` | Links to the scope spec, peer role specs, working agreements, and decisions that govern this role's boundaries. |

### Lifecycle states

| State | Meaning |
|---|---|
| `draft` | Authored by the owner; not yet reviewed or accepted by the incumbent |
| `agreed` | Incumbent has reviewed and accepted the spec in its current form (recorded inline as a response in the scope's feedback inbox) |
| `active` | Agreed and in effect |
| `under-review` | Active but under renegotiation — the spec should not be treated as settled |

A spec must not be set to `active` without a recorded incumbent acceptance. The acceptance record lives in the scope's `feedback.md` — an inline response from the incumbent confirming the spec.

### Location convention

Role specs live under a `roles/` subfolder within the scope that owns the function or team:

```
<scope>/roles/<role-slug>.md
```

A scope that has a `roles/` folder should also maintain a `roles/README.md` or `roles/coverage.md` mapping the scope's accountability structure — what is covered, what is held by the scope lead directly, and what is a known gap.

### Relationship to `people`

`people.md` and role specs are complementary, not duplicative:

- `people.md` answers: *who holds roles at this scope, and what authority do they have?* It is a roster and authority declaration, queryable by tools.
- A role spec answers: *what is this role accountable for, what does it own, and how is success measured?* It is an accountability contract between manager and incumbent.

A scope may have a `people.md` without role specs (valid for small scopes). A scope may have role specs without listing every person in `people.md`. When both exist, the incumbent named in the role spec's frontmatter must match the relevant row in `people.md`.

## What is not prescribed

- **Whether every scope has role specs.** Small scopes with few contributors may operate from `people.md` alone.
- **The depth of accountability items.** A role spec may be as brief or as detailed as the scope requires; the required sections define the shape, not the word count.
- **How success metrics are set.** The spec requires outcome-linked criteria; it does not prescribe whether they are set by the manager, negotiated with the incumbent, or derived from org-level targets.
- **How frequently the spec is reviewed.** The lifecycle states provide signals; the review cadence is the scope's to decide.

## Rationale

**Rosters and accountability structures are different things.** The `people` capability defines who holds roles at a scope. It does not define what those roles are — what they own, what they owe peers, how success is measured. Without a shared pattern for this, organisations either produce prose job descriptions that tools cannot parse, embed accountability in narrative specs that mix structural and content concerns, or rely on informal understanding that exists only in people's heads. All three fail when the org grows, when roles change hands, or when accountability gaps need to be surfaced systematically.

**The bilateral peer relationship is the key gap.** A job description typically describes what a role does. What it rarely captures is the *bilateral contract* with each peer: what this role owes peer A, and what peer A owes it in return. Without explicit bilateral tables, peer interfaces exist only in verbal agreements that do not survive handovers. A role spec makes these contracts visible and auditable.

**Owner and incumbent are distinct concepts that collapse without a schema.** The person who defines a role's accountabilities (typically the manager) is not the same as the person currently performing the role. A role spec can be authored and owned before it has an incumbent, and it persists after a person leaves. Conflating the two makes it impossible to tell whether a spec is current, vacant, or draft.

**The incumbent agreement signal matters.** A role spec that the incumbent has not accepted is a proposal, not a contract. Without a lifecycle that distinguishes draft → agreed → active, a repo may contain role specs that look authoritative but have never been accepted by the person they govern. This creates false certainty.

**Success criteria anchored to activities rather than outcomes is the dominant failure mode.** Most job descriptions define what a role does (activities) rather than what it produces (outcomes). This capability requires success criteria to be measurable, outcome-linked, and tied to org-level results where possible — making accountability legible to a third-party reader, not just the manager who wrote it.

## Related

- [`../people/spec.md`](../people/spec.md) — roster and authority declarations; complementary to role specs
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — incumbent acceptance is recorded as a feedback entry
- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — scope governance that role specs operate within
- [`../../proposals/teams.md`](../../proposals/teams.md) — teams as a first-class artefact; team members may have role specs
- [`../../proposals/working-agreement.md`](../../proposals/working-agreement.md) — bilateral agreements between scopes; peer tables in role specs are the per-role view of what working agreements formalise at scope level
