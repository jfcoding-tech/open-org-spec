# People at scope

A capability of open-org-spec describing how the people who hold roles in a scope are modelled: where their record lives, what every people file must declare, and how a person's role in one scope relates to their role in another.

**Status:** Draft (0.1.0)

## Purpose

Every scope in a conformant repository — a module, a cluster, a cross-cutting team — has people who hold roles within it. Without a canonical shape, each scope re-invents its own: some collapse job title, organisational affiliation, and function into a single "Role" column; others list only names; others conflate scope-specific function with org-wide title. The result is a repo where "who does what here" takes prose-walking to answer, role queries across scopes are unreliable, and newcomers cannot read authority at a glance.

This capability codifies the recurring pattern so adopters have a consistent, queryable shape from the first scope they model.

## Pattern

### Where the record lives

Each scope carries a single `people.md` file at its root. The file is **scope-local**: it describes people's roles *at this scope*, not across the organisation. A person who holds different roles in two scopes appears in each scope's `people.md` with the role that applies there.

Absence of a `people.md` at a scope is valid — it means the scope has no named working group beyond what higher-scope files already declare.

### Two-table shape

A `people.md` contains two distinct tables with different concerns. Mixing them into one table is not permitted.

#### 1. Lead table

A structural single-row table identifying the scope's accountable lead. Kept narrow — three columns only:

| Name | Role | Authority |
|---|---|---|
| … | … | … |

- **Name** — full name as recorded in HR.
- **Role** — the lead's title or function at this scope (e.g. "Cluster Lead", "Module Owner").
- **Authority** — a one-sentence declaration: what the lead may edit, and what they are accountable for. This is the governance surface: a contributor or LLM reading this table should be able to answer "who owns this scope and what can they unilaterally change?"

The lead table is mandatory. A scope without a named lead is ungoverned. If the lead is not yet assigned, use `TBD` in all cells; the scope is in provisional state.

#### Lead table and decision authority

The Authority field is a **minimal accountability declaration** — sufficient for scopes that have no governance folder. It answers "who is accountable here and what can they unilaterally change?" in one human-readable sentence.

It is not a substitute for DACI. When a `governance/` folder exists at the same scope (per the [`governance-at-scope`](../governance-at-scope/spec.md) capability), the DACI frontmatter declared there is the authoritative source for decision-making: who drives, who approves, who is consulted. In that case the Authority field remains as a readable summary but does not supersede or contradict the governance DACI.

The two are composable by design: `people.md` can exist without a governance folder (the lead table alone is sufficient for small scopes); a governance folder can exist without a `people.md` (it declares decision authority without listing the full working group). When both exist at the same scope, `people.md` answers "who is here?" and `governance/README.md` answers "who decides here?" — neither duplicates the other.

#### 2. Working group table

A five-column table for everyone else who holds a role in the scope:

| Name | Job title | Affiliation | Function | Areas in scope |
|---|---|---|---|---|
| … | … | … | … | … |

- **Name** — full name as recorded in HR.
- **Job title** — HR title, verbatim. Never a function or a scope-specific role — that is the Function column's job. Use `TBD` if not yet known.
- **Affiliation** — the person's organisational home: their squad, cluster, module, function, or `external`. Identical for the same person across all scopes they appear in. Use `TBD` if not yet known.
- **Function** — the role played *at this scope*, picked from the closed vocabulary below. This is the only column that changes when the same person appears in multiple scopes.
- **Areas in scope** — concrete workflows, projects, capabilities, or domains this person is responsible for within this scope. May be empty when function alone is sufficient context.

The working group table is optional when the scope has only a lead and no named working group. When it exists, every row must have a Function from the vocabulary; `TBD` is valid only when the person's involvement is confirmed but the specific function is not yet decided.

### Function vocabulary (closed set)

The Function column picks from this set. Candidate functions outside this set are added by follow-up revision to this capability, not invented inline.

- **Owner** — accountable for the spec or module's content. At most one per scope at any time.
- **Lead** — operational lead of a cluster or module. Typically also the lead-table entry.
- **Driver** — operational lead of an initiative, capability, or project within this scope.
- **Approver** — sign-off authority on decisions made at this scope.
- **Liaison** — connects this scope to another (e.g., Engineering liaison to a business cluster, cross-cluster representative).
- **Contributor** — actively authors or maintains specs at this scope.
- **Member** — participant in the scope's working group without a more specific function above. The default when someone belongs but no narrower role applies.

The vocabulary is intentionally small. More-specific functions belong in the spec-level DACI headers of individual decisions or projects, not in the people roster. The people file describes standing roles; DACI describes per-decision authority.

**Representation is extension-overridable.** The two-table markdown shape shown above is the default. Adopters may declare a different form (e.g., YAML records, CSV, a single combined table with additional columns) in their extension spec, provided the two concerns remain distinct (lead vs working group), every required column remains present, and the extension declares the mapping. The capability requires the columns and the distinction between the two tables, not the syntactic form. Extensions may also add columns or extend the Function vocabulary; removing required columns, collapsing the two tables, or replacing the closed function vocabulary with an open one is not authorised by this override — only the form changes; the contract does not.

### Consent and acknowledgement

A row in `people.md` is not just data — it assigns accountability. Adding someone in a function without their knowledge means they may be held responsible for something they never agreed to.

The rule: **a row added by someone other than the named person is not authoritative until that person explicitly acknowledges it.** The canonical acknowledgement mechanism is a feedback entry addressed to the named person at the scope's `feedback.md`; their inline response closes the loop.

Until acknowledged, the row carries a `(pending acknowledgement)` marker in the Function cell:

```
| Jordan Lee | … | … | Driver (pending acknowledgement) | … |
```

**Authority functions — Owner, Driver, Approver — make the feedback entry mandatory.** These functions carry real accountability; the named person must know they hold them. Liaison, Contributor, and Member follow the same rule at lower urgency — no one is enrolled in a working group without knowing.

**A person adding themselves does not need acknowledgement.** Self-declaration is sufficient; the row is authoritative from the moment it is committed.

When Claude adds a person to `people.md` at another contributor's instruction, it opens the feedback entry automatically before or alongside committing the row. The row lands with `(pending acknowledgement)`; the marker is removed when the named person responds.

### Edge cases

- **Same person, two scopes.** One row per scope, each with the Function that applies there. Job title and Affiliation are identical; Function may differ (Lead in their own cluster, Liaison elsewhere).
- **Workshop attendee with no ongoing role.** Does not appear. `people.md` lists active roles, not attendance history.
- **Job title or affiliation changes.** Updated when detected. The file carries a `**Last verified:** YYYY-MM-DD` line below the working group table; update it on each sweep.
- **Unknown job title or affiliation at row creation.** Use `TBD`. The row is valid — the Function is real even when metadata is incomplete.
- **Person holds two functions at the same scope.** Record the narrower / more specific one. If genuinely two distinct functions apply (e.g. both Driver and Approver on different sub-projects), either add two rows (one per function) or list both in the Function cell separated by ` + `. Do not silently drop one.

### Additional named-person sections

Some scopes carry sections beyond the two main tables — for example, an "Engineering liaison" subsection in a cluster file, or a "Cross-cluster representative" block. These follow the same five-column working group shape. The two-table convention is a minimum, not a ceiling.

## What is not prescribed

- **Whether every scope has a `people.md`.** Absence is valid. Small scopes governed entirely by higher-scope rules often need no local people file.
- **FTE inventories and headcount tables.** Role-by-headcount tables that list role types without naming individuals are out of scope. This capability governs named-person records, not role taxonomies.
- **How people data flows into tooling.** This capability defines the schema; how a tool queries it (prose walk, structured catalogue, generated index) is a separate concern, addressed in the adopter's tooling layer.
- **The number of named people in scope.** No minimum or maximum. A module with a single named Owner and no other working group is fully conformant.
- **A specific folder name other than `people.md`.** The name is convention-bound. Adopters using a different name lose interop with tools that target this convention by default.

## Rationale

The problem this capability solves is role ambiguity across scopes: a "Role" column that collapses job title, affiliation, and function into one cell makes it impossible to answer "who holds authority here?" without reading prose, and impossible for a tool to do so at all without guessing.

Separating the three concerns — title (what HR calls you), affiliation (where you belong organisationally), function (what you do at this scope) — into explicit columns makes each answerable independently. The closed function vocabulary keeps the Function column machine-readable without forcing adopters into an ever-expanding taxonomy: most scope-level roles reduce to one of seven functions; exceptions surface as proposals to extend the standard, not as silent ad-hoc entries.

The two-table shape — lead structural, working group five-column — preserves the qualitative difference between "the person accountable for this scope" and "people who work within it." A tool querying "who owns this module?" can answer with a single row read; a tool querying "who are the Engineers here?" can filter the working group table by Affiliation. Neither query requires prose-walking.

## Adoption

*(A guided `oos:people` command is deferred pending a second adopter instance. Until then, apply the pattern manually: create `<module>/people.md`, write the lead table, add the working group table if the scope has named members beyond the lead.)*

## Related

- [`governance-at-scope/spec.md`](../governance-at-scope/spec.md) — defines who holds decision authority at each scope (DACI). People at scope is complementary: it describes standing membership, not per-decision authority. The two together answer "who is here?" and "who decides here?"
- [`../../backlog.md`](../../backlog.md) — "People-as-spec: per-module `people.md` as a standard-level concept" (added 2026-04-30). This spec is its graduation.
