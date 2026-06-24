---
change: roles
status: draft
opened: 2026-06-24
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Role specs — accountabilities, peers, and success within a scope

## Intent

Introduce `roles` as a first-class capability defining how individual accountabilities are specified within a scope. A role spec is a structured artefact that answers: what does this role exist to do, what does it own, how does it work with peers, and what does success look like. It is richer than a `people.md` roster entry and distinct from it — `people.md` answers *who is here*; a role spec answers *what this position is accountable for and why*.

## Rationale

**Rosters and accountability structures are different things.** The `people` capability defines who holds roles at a scope. It does not define what those roles are — what they own, what they owe peers, how success is measured. Without a shared pattern for this, organisations either produce prose job descriptions that tools cannot parse, embed accountability in narrative specs that mix structural and content concerns, or rely on informal understanding that exists only in people's heads. All three fail when the org grows, when roles change hands, or when accountability gaps need to be surfaced systematically.

**The bilateral peer relationship is the key gap.** A job description typically describes what a role does. What it rarely captures is the *bilateral contract* with each peer: what this role owes peer A, and what peer A owes it in return. Without explicit bilateral tables, peer interfaces exist only in verbal agreements that do not survive handovers. A role spec makes these contracts visible and auditable.

**Owner and incumbent are distinct concepts that collapse without a schema.** The person who defines a role's accountabilities (typically the manager) is not the same as the person currently performing the role. A role spec can be authored and owned before it has an incumbent, and it persists after a person leaves. Conflating the two makes it impossible to tell whether a spec is current, vacant, or draft.

**The incumbent agreement signal matters.** A role spec that the incumbent has not accepted is a proposal, not a contract. Without a lifecycle that distinguishes draft → agreed → active, a repo may contain role specs that look authoritative but have never been accepted by the person they govern. This creates false certainty.

**Success criteria anchored to activities rather than outcomes is the dominant failure mode.** Most job descriptions define what a role does (activities) rather than what it produces (outcomes). This capability requires success criteria to be measurable, outcome-linked, and tied to org-level results where possible — making accountability legible to a third-party reader, not just the manager who wrote it.

## Delta

New capability: `specs/roles/spec.md`.

### Role spec schema

A role spec is a markdown file with YAML frontmatter and a required set of sections.

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

Examples:
- `functions/engineering/roles/engineering-lead.md`
- `clusters/product/roles/product-manager.md`

A scope that has a `roles/` folder should also maintain a `roles/README.md` or `roles/coverage.md` mapping the scope's accountability structure — what is covered, what is held by the scope lead directly, and what is a known gap.

### Relationship to `people`

`people.md` and role specs are complementary, not duplicative:

- `people.md` answers: *who holds roles at this scope, and what authority do they have?* It is a roster and authority declaration, queryable by tools.
- A role spec answers: *what is this role accountable for, what does it own, and how is success measured?* It is an accountability contract between manager and incumbent.

A scope may have a `people.md` without role specs (the scope has named leads but their accountabilities are not formally specified — valid for small scopes). A scope may have role specs without listing every person in `people.md` (the spec defines the role; the roster records who holds it).

When both exist, they must be consistent: the incumbent named in the role spec's frontmatter must match the relevant row in `people.md`.

## Acceptance scenarios

### Manager authors a role spec before the role is filled

Given a scope that has a vacancy
When the scope lead authors a role spec with `status: draft` and `incumbent: vacant`
Then the spec records the accountability structure for the role before a person is hired
And tools scanning the scope surface the spec as a vacant role
And the spec moves to `agreed` only after an incumbent accepts it

### Incumbent accepts a role spec

Given a role spec at `status: draft` authored by the scope lead
When the incumbent reviews the spec and records their acceptance in the scope's `feedback.md`
Then the spec moves to `status: agreed`
And the acceptance record is auditable (named, dated, inline in the feedback file)
And the spec may then be set to `active`

### Peer interface is surfaced by a tool

Given two role specs in the same scope, each with a peer table
When a tool reads both specs
Then it can derive the bilateral interface between the two roles
And flag any row where role A claims to owe something to role B that role B's spec does not declare as a dependency
And surface mismatches as conformance gaps

### Coverage gap is identified

Given a scope with a `roles/coverage.md` and a set of role specs
When a tool compares the scope lead's accountability list against the role specs
Then it identifies accountabilities that are not covered by any role spec
And surfaces them as gaps to the scope lead
And distinguishes gaps that are held by the lead by design from genuine unowned accountabilities

### Role changes hands

Given a role spec at `status: active` with a named incumbent
When the incumbent changes
Then the spec's `incumbent` field is updated and `status` is reset to `draft`
And the new incumbent goes through the acceptance process before the spec returns to `active`
And the prior incumbent's acceptance record in `feedback.md` is preserved as historical record

## Related

- `specs/people/spec.md` — roster and authority declarations; complementary to role specs
- `specs/feedback-inbox/spec.md` — incumbent acceptance is recorded as a feedback entry
- `specs/governance-at-scope/spec.md` — scope governance that role specs operate within
- `proposals/teams.md` — teams as a first-class artefact; team members may have role specs
- `proposals/working-agreement.md` — bilateral agreements between scopes; peer tables in role specs are the per-role view of what working agreements formalise at scope level
