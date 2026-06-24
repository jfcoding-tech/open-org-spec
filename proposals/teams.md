---
change: teams
status: draft
opened: 2026-06-24
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: teams capability

## Intent

Introduce `team` as a first-class artefact in the standard. A team is a named group of people working together within or across scopes — distinct from a function, a cluster, a project, or a people roster. Team specs live inside their parent scope, replace person-specific dotted-line files, and make dotted-line relationships a property of the team rather than of the individual.

## Rationale

**The gap between roster and scope.** The standard currently offers two artefacts for describing people: `people.md` (who is in a scope) and scope specs (function, cluster, project — what the scope does). Neither describes the internal structure of a scope: how people group, what sub-units exist, and how those units relate to each other or to units in other scopes. Adopters fill this gap ad-hoc — creating person-named files, nested folders with no declared type, or extending project specs to cover what are effectively permanent teams.

**Dotted-line relationships accumulate as person files.** The most visible failure mode: when an individual has a formal but non-reporting relationship to another scope, adopters create a file named after the person to encode it. This produces duplicated information (the relationship is also in the parent scope's spec), person-specific artefacts that are hard to find, and stale data when the person changes roles. The correct encoding is a property of the team, not the person — if the Brain team has a dotted line to DI&D, that belongs on the Brain team spec, not on each member's file.

**Working groups have no lifecycle.** A time-bounded cross-scope working group is a real, recurring pattern: a group that forms to solve a specific problem, operates for months, and then dissolves. Without a declared type, working groups either get modelled as projects (forcing artificial lifecycle gates) or as functions (implying permanence they don't have). A `team` artefact with a `type: working-group` makes the lifecycle expectation explicit at creation.

**Teams are generic.** The pattern applies across organisations of any size: an engineering sub-team within a cluster, a product pod, a cross-functional squad, a temporary working group. The artefact is simple enough to be universally useful without over-prescribing internal structure.

## Delta

New capability: `specs/teams/spec.md`.

### Team spec schema

A team spec is a markdown file at `<parent-scope>/teams/<team-name>/spec.md`. The spec declares:

| Field | Description |
|---|---|
| `name` | Short name for the team |
| `purpose` | One sentence: what this team exists to do |
| `type` | `permanent` — ongoing sub-unit of a scope; `working-group` — time-bounded, has a close criterion |
| `lead` | Accountable person for this team |
| `parent_scope` | Path to the scope this team sits within |
| `members` | Inline list or pointer to `people.md` in the same folder |
| `dotted_lines` | List of `{ scope, purpose }` — formal non-reporting relationships this team holds with other scopes. One entry per relationship; the `purpose` field explains why the relationship exists and what it covers. |
| `close_criterion` | Required for `type: working-group`; omitted for permanent teams |
| `related` | Links to parent scope spec, working agreements, and any sibling team specs |

### Location convention

Teams live inside their parent scope:

```
<parent-scope>/
  teams/
    <team-name>/
      spec.md        # team spec
      people.md      # optional — if members need a roster
```

A team folder does not have its own `governance/` or `decisions/` subfolder by default. If a team reaches a scale where it needs its own governance, that is a signal it should become a first-class scope (function or cluster), not a team.

### Dotted-line encoding

The `dotted_lines` field replaces person-specific dotted-line files. A dotted line is a property of the team, not the individual. The scope on the other end of the relationship may reference back via a working agreement (see `working-agreement` capability) or via a `related` link, but is not required to mirror the dotted_lines entry.

Example:

```yaml
dotted_lines:
  - scope: functions/decision-intelligence
    purpose: Brain layer output feeds the intelligence layer; joint participation in DI Leads Weekly cadence
```

### Catalogue integration

The `catalogue` capability's scope walker adds teams to the scope index under a `teams` key, linked to their parent scope. Teams are not top-level scopes — they appear as children. This makes them discoverable without polluting the top-level scope list.

## Acceptance scenarios

### Permanent sub-team within a function

Given a function with two named sub-teams (e.g. Data Engineering and Customer Intelligence)
When each sub-team has a `spec.md` at `functions/decision-intelligence/teams/<name>/spec.md`
Then each spec declares `type: permanent`, its lead, members, and `dotted_lines` if applicable
And the parent function's spec can reference its teams via a `teams:` block or relative links
And the catalogue indexes both teams under the parent function

### Dotted-line relationship replaces person files

Given a team that has a formal non-reporting relationship with another scope
When the dotted line is declared in the team spec's `dotted_lines` field
Then no separate person-named file is needed to encode the relationship
And the relationship is visible to anyone reading either the team spec or the other scope's spec (via a linked working agreement or `related` pointer)
And when team membership changes, the dotted-line record is unchanged — it belongs to the team, not the person

### Working group with a close criterion

Given a cross-functional working group that forms to design an operating model
When the group's spec declares `type: working-group` and a `close_criterion`
Then contributors and tools can distinguish it from a permanent team
And when the criterion is met, the team spec is archived (moved to a `closed/` subfolder) with an `outcome` note
And what the working group produced (a spec, a decision, a working agreement) is linked from the archived spec

### Working group without a close criterion is flagged

Given a team spec with `type: working-group` and no `close_criterion`
When the conformance agent scans the scope
Then it writes a `[gap]` notice to the team lead's feedback inbox: the close criterion is required for working groups

### Catalogue surfaces team count per scope

Given a scope with three sub-teams
When `/catalogue` runs
Then the catalogue output includes a `teams` field for that scope listing the three team names, their leads, and their types
And a reader navigating the catalogue can find all teams in the org without walking the full file tree

## Related

- `specs/people/spec.md` — roster artefact; a team's `people.md` follows the same conventions
- `specs/function/spec.md` — parent scope type; a team lives inside a function
- `specs/governance-at-scope/spec.md` — teams do not have their own governance by default; if they need it, they should become a first-class scope
- `proposals/working-agreement.md` — dotted-line relationships between teams often warrant a working agreement to formalise what each side owes the other
