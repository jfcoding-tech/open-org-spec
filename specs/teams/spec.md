# Teams

A capability for declaring named groups of people working together within or across scopes — distinct from a function, a cluster, a project, or a people roster.

**Status:** Active (0.19.0)

## Purpose

A team is a named group of people working together within or across scopes. The standard's existing artefacts — `people.md` (who is in a scope) and scope specs (function, cluster, project) — do not describe a scope's internal structure: how people group, what sub-units exist, and how those units relate to each other or to units in other scopes. The `teams` capability fills this gap.

The most visible failure mode this capability resolves: when an individual has a formal but non-reporting relationship to another scope, adopters create a file named after the person to encode it. The correct encoding is a property of the team, not the person — if a team has a dotted line to another scope, that belongs on the team spec, not on each member's file.

## Pattern

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

The `dotted_lines` field replaces person-specific dotted-line files. A dotted line is a property of the team, not the individual. The scope on the other end of the relationship may reference back via a working agreement (see [`working-agreement`](../working-agreement/spec.md)) or via a `related` link, but is not required to mirror the `dotted_lines` entry.

Example:

```yaml
dotted_lines:
  - scope: functions/decision-intelligence
    purpose: Brain layer output feeds the intelligence layer; joint participation in DI Leads Weekly cadence
```

### Working-group lifecycle

A team spec with `type: working-group` must declare a `close_criterion` — the concrete condition that dissolves the group. When the criterion is met, the team spec is archived (moved to a `closed/` subfolder within `teams/`) with an `outcome` note linking to what the working group produced.

A working-group spec missing `close_criterion` is a conformance gap. The conformance agent writes a `[gap]` notice to the team lead's feedback inbox.

### Catalogue integration

The `catalogue` capability's scope walker adds teams to the scope index under a `teams` key, linked to their parent scope. Teams are not top-level scopes — they appear as children. This makes them discoverable without polluting the top-level scope list.

## What is not prescribed

- **Whether every scope has teams.** Absence is valid. Small scopes with a single contributor or a flat structure may not need named sub-groups.
- **The depth of team nesting.** The standard names one level (teams within a scope). Sub-teams within a team are not prohibited but are not governed by this capability — if a sub-team is needed, consider whether the parent team should become a first-class scope instead.
- **Membership granularity.** A team spec may list members inline or point to a `people.md` file. Both are valid.
- **Whether dotted-line targets acknowledge the relationship.** The scope named in `dotted_lines` is not required to mirror the entry or maintain a reciprocal pointer. The working-agreement capability is the appropriate mechanism when both parties need to formalise the relationship.

## Rationale

**The gap between roster and scope.** The standard currently offers two artefacts for describing people: `people.md` (who is in a scope) and scope specs (function, cluster, project — what the scope does). Neither describes the internal structure of a scope: how people group, what sub-units exist, and how those units relate to each other or to units in other scopes. Adopters fill this gap ad-hoc — creating person-named files, nested folders with no declared type, or extending project specs to cover what are effectively permanent teams.

**Dotted-line relationships accumulate as person files.** The most visible failure mode: when an individual has a formal but non-reporting relationship to another scope, adopters create a file named after the person to encode it. This produces duplicated information (the relationship is also in the parent scope's spec), person-specific artefacts that are hard to find, and stale data when the person changes roles. The correct encoding is a property of the team, not the person — if the Brain team has a dotted line to DI&D, that belongs on the Brain team spec, not on each member's file.

**Working groups have no lifecycle.** A time-bounded cross-scope working group is a real, recurring pattern: a group that forms to solve a specific problem, operates for months, and then dissolves. Without a declared type, working groups either get modelled as projects (forcing artificial lifecycle gates) or as functions (implying permanence they don't have). A `team` artefact with a `type: working-group` makes the lifecycle expectation explicit at creation.

**Teams are generic.** The pattern applies across organisations of any size: an engineering sub-team within a cluster, a product pod, a cross-functional squad, a temporary working group. The artefact is simple enough to be universally useful without over-prescribing internal structure.

## Related

- [`../people/spec.md`](../people/spec.md) — roster artefact; a team's `people.md` follows the same conventions
- [`../function/spec.md`](../function/spec.md) — parent scope type; teams live inside a function or equivalent scope
- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — teams do not have their own governance by default; if they need it, they should become a first-class scope
- [`../working-agreement/spec.md`](../working-agreement/spec.md) — dotted-line relationships between teams often warrant a working agreement to formalise what each side owes the other
