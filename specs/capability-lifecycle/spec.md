# Capability lifecycle

A capability of open-org-spec defining the workflow by which capabilities, templates, and other normative content of a conformant repository are added, changed, or retired. Self-describing: this workflow is itself a capability under `specs/`.

**Status:** Draft (0.1.0)

## Purpose

Normative content in open-org-spec (and in conformant adopter repositories) needs a consistent way to evolve. Without one, each change re-invents its own sequence, documentation shape, and commit discipline. A shared lifecycle provides: a stable sequence of stages, defined artefacts per stage, and clear transitions — so the history of changes is auditable and the shape of a proposal is predictable.

## Use and extension

This workflow is **not mandatory**. A repository conforms to open-org-spec as long as its artefacts match the schema of each capability it adopts; how those artefacts came to exist is not part of conformance. An adopter may use any process — or none — to produce conformant content.

The workflow is provided as an **opinionated default**: a shared thinking process from problem framing through exploration, proposal, application, and archive. Its value is consistency — when contributors follow the same sequence with the same artefacts, the resulting history is auditable, proposals take a predictable shape, and the decisions embedded in each change (intent, delta, acceptance scenarios, decision authority where applicable) are recorded in a comparable form across changes.

Adopters are free to **extend or override** the defaults. Common cases:

- A **regulated process** — legal, compliance, audit, formal sign-off — may require additional artefacts or stages. Adopters add them, typically via a scope-level governance extension.
- An organisation may prefer **different cadence, artefact names, or mode semantics** for its own repository. These are local choices and do not affect the standard.

The standard defines the shape of the default. The standard does not compel its use.

## Stages

Five stages, in order:

1. **problem** — surfaces what's broken, establishes evidence, states the closure condition. Required artefact: `problem.md`. See [`../../templates/problem.md`](../../templates/problem.md).
2. **exploration** (optional) — investigates options, records reasoning, captures tradeoffs. When used: `exploration.md`. Free-form prose; the lifecycle does not prescribe a schema.
3. **proposal** — formalises the change. Required artefacts: `proposal.md` (see "Proposal shape" below) and, when the change produces normative content, one or more `<area>-delta/` subfolders (see "Delta folders" below).
4. **apply** — moves the delta contents into their final paths and updates the proposal's status to `applied`.
5. **archive** — moves the completed change folder into `archive/<YYYY-MM-DD>-<slug>/`.

## Artefact layout

Active change:

```
changes/<slug>/
  problem.md
  exploration.md                  (optional)
  proposal.md
  <area>-delta/                   (zero or more; one per target area — see "Delta folders")
```

Archived change:

```
archive/<YYYY-MM-DD>-<slug>/
  (the change's files at archive time, without the delta folders, which have been applied)
```

`archive/` is a peer of `changes/` at the repository root (or the adopter's repository root in adopt mode), not nested inside it. In-flight changes and historical record are distinct concerns; peer folders keep that distinction legible.

The archive folder is immutable once written. Subsequent changes do not re-enter or modify archived changes; they open new change folders.

## Proposal shape

Every `proposal.md` carries YAML frontmatter and a prose body. See [`../../templates/proposal.md`](../../templates/proposal.md) for the starter.

### Frontmatter (required)

```yaml
---
change: <slug>
status: proposed | applied | cancelled
opened: YYYY-MM-DD
mode: develop | adopt
owner:
  name: <full name>
  role: <organisational role>
---
```

- `change` — slug of the change; matches the folder name.
- `status` — one of `proposed`, `applied`, `cancelled`. Transitions are pull requests.
- `opened` — the date the proposal entered `proposed` status.
- `mode` — see "Modes" below. Tells `apply` where the delta lands.
- `owner` — the role accountable for the change reaching done (or being cancelled). Owner schema matches `governance-at-scope`.

### Prose body

At minimum:

- **Intent** — one paragraph on what the change does.
- **Delta** — pointer to the `<area>-delta/` subfolder(s) (or prose description if the change has no structural spec delta).
- **Acceptance scenarios** — at least one Given/When/Then scenario. A proposal with no acceptance scenario cannot be applied.

Optional, when applicable:

- **Decision authority** — required when the change produces a recommendation rather than executing on a known direction. Names the role or body that decides on the recommendation.

## Modes

The lifecycle supports two modes; a repository is in exactly one at a time:

- **develop** — the repository is open-org-spec itself (or a fork intended to contribute upstream). `changes/` lives at the repository root. `apply` moves delta contents into the repository's `specs/` and `templates/` folders. This is the mode in which normative content of the standard itself evolves.
- **adopt** — the repository is an adopter of open-org-spec. `changes/` lives at the adopter's repository root. `apply` moves delta contents into the adopter's own specs and governance folders. The vendored or referenced `open-org-spec/` is **read-only**: no change may target paths under it. To change the standard itself, adopters contribute upstream.

The enforcement mechanism for `open-org-spec/` read-only in adopt mode is out of scope for this capability; see [`../../backlog.md`](../../backlog.md).

## Delta folders

A change folder contains zero or more `<area>-delta/` subfolders, each holding content in the exact shape it will occupy after apply. Apply rule, per area:

- `specs-delta/<path>` → `specs/<change-slug>/<path>`
- `templates-delta/<path>` → `templates/<path>`
- `<area>-delta/<path>` → `<area>/<path>` for any other top-level area (applies in adopt mode to adopter areas such as `governance-delta/` or `clusters-delta/`).

The folder name tells apply where content lands. Reviewers read the resulting content in its final form rather than reconstructing it from a prose description of changes.

`specs-delta/` is the only area whose target folder name is derived from the change slug. This matches the common case: one change adds or fully replaces one capability, whose name matches the slug. Modifying an existing capability whose name differs from the slug is not supported at v0; the rule is refined when that case arises (e.g., a `targets:` field in proposal frontmatter).

In adopt mode, the same rules apply. Paths that would resolve to `open-org-spec/` are refused at apply time.

## Apply semantics

When a change's proposal is applied:

1. Each file under each `<area>-delta/` subfolder is moved to its final path, per the rules in "Delta folders" above.
2. If any target path already exists, the apply refuses — the proposal must be revised to handle the pre-existing content explicitly (rename, delete, or merge intent). Silent overwrite is not permitted.
3. The proposal's frontmatter `status` is updated to `applied`.
4. The now-empty `<area>-delta/` subfolders are removed.
5. The change folder (containing `problem.md`, optional `exploration.md`, and `proposal.md` with `status: applied`) remains in place pending archive.

The apply operation is deliberately small — move content, update status. Larger transformations (pruning, migrating pre-existing content) are separate changes, proposed and applied on their own merits.

See [`apply.md`](./apply.md) for the command file.

## Archive semantics

When a proposal's `status` is `applied` or `cancelled`:

1. The folder `changes/<slug>/` is moved to `archive/<YYYY-MM-DD>-<slug>/`. The date is the archive date, not the opening date. `archive/` is a peer of `changes/` at the repository root, not nested.
2. Subsequent changes do not re-open or modify the archived folder.

A cancelled change is archived with its status preserved. The archived folder still carries `status: cancelled`; the proposal body should include a short note explaining why the change was cancelled.

## Cancellation

A `proposed` change may transition to `cancelled` at any time. The proposal's frontmatter `status` is updated and a short cancellation note is added to the body. The change is then archived.

## What capability-lifecycle is not

- **A workflow for an adopter's operational initiatives.** open-org-spec does not currently prescribe a lifecycle for time-bound operational work inside an adopter organisation. If such a capability is needed, it is added separately.
- **A deployment pipeline.** `apply` moves files and updates status. Deployment to downstream systems, regeneration of derived artefacts, and version tagging are out of scope.
- **A review system.** The workflow defines what exists at each stage; review mechanics (who must approve, when, and how sign-off is recorded) are governance concerns covered by `governance-at-scope` at the relevant scope.

## Not prescribed

- **Commit cadence.** Whether each stage produces its own commit or multiple stages are batched into one commit is left to the contributor and the adopting repository's conventions.
- **Exploration shape.** When used, `exploration.md` is free-form prose.
- **Dependency between changes.** v0 does not model cross-change dependencies (a change that can only apply after another). If the pattern recurs, a later proposal adds it.
- **Versioning on apply.** Whether an applied change triggers a version bump is out of scope at v0; the standard is under active development and does not publish versions. A later proposal may add versioning when the standard stabilises.

## Rationale

Three design choices are load-bearing:

1. **Self-describing.** The workflow is itself a capability, proposed and applied through its own stages. This means the standard has no "meta-layer" above the capability layer — every normative piece of content is a capability, added the same way.
2. **Delta by final shape.** Authoring the delta inside `<area>-delta/` subfolders in its final form (rather than as a prose description of what will change) means reviewers read the resulting content in situ. Apply becomes a mechanical move, not an interpretation.
3. **Mode explicit on every proposal.** Develop vs. adopt is a property of the change, not only the repository. An adopter in adopt mode can still fork open-org-spec and open a develop-mode change against that fork; the `mode` field on the proposal makes this explicit.

## Invocation

- **Propose, archive, cancel.** File-authoring operations described in "Stages," "Archive semantics," and "Cancellation." No separate command file at v0.
- **Apply.** Mechanical; see [`apply.md`](./apply.md).

## Related

- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — the first capability; landed ad-hoc and motivated this workflow.
- [`../adherence-check/spec.md`](../adherence-check/spec.md) — the first capability landed through this workflow (simulation co-run with the lifecycle itself).
- [`../../templates/problem.md`](../../templates/problem.md), [`../../templates/proposal.md`](../../templates/proposal.md) — starters for new changes.
- [`../../backlog.md`](../../backlog.md) — related entries: *command protocol for `oos:` commands*, *migration mode for `oos:adopt-*` commands*, *adopter-state detection protocol*, *two-layer catalogue*.
