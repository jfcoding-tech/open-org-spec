# Project

A concept capability of open-org-spec defining the schema for time-boxed work an adopter organisation undertakes. Covers experimental work (hypothesis-testing) and execution work (delivering a known outcome) via the same shape, with optional fields for the variation.

**Status:** Draft (0.1.0)

## Purpose

Adopters produce time-boxed work — POCs, experiments, initiatives, delivery projects — routinely. Without a shared schema, each adopter (and each user within an adopter) re-invents the shape, producing divergent `spec.md` files that can't be read as a category. The `project` capability provides a minimum conformant shape: opinionated, but narrow enough that it doesn't force adopters into a template they'll fight.

## Pattern

### Artefact location

A project's artefact lives at `projects/<slug>/spec.md` in the adopter's repository root. The standard does not prescribe alternate folder names at v0; an adopter using `initiatives/` or `experiments/` instead is operating outside conformance (see "Not prescribed").

### Schema

A project's `spec.md` carries YAML frontmatter and a prose body.

#### Frontmatter (required)

```yaml
---
project: <slug>
status: started | proposed | in-progress | closed | cancelled
opened: YYYY-MM-DD
closed: YYYY-MM-DD     # present only when status is `closed` or `cancelled`
owner:
  name: <full name>
  role: <organisational role>
tooling:
  <tool-name>:
    first: YYYY-MM-DD
    last: YYYY-MM-DD   # present only when last-use differs from first-use
    by: <contributor name>
---
```

- `project` — slug, matching the folder name under `projects/`.
- `status` — one of five values; transitions are local edits (see "Status semantics").
- `opened` — date the project artefact was created.
- `closed` — date the project was closed or cancelled; absent while the project is `started`, `proposed`, or `in-progress`.
- `owner` — the role accountable for the project reaching close (or being cancelled). Schema matches `governance-at-scope`'s owner.
- `tooling` — record of state-changing tools that have written to this spec; see [Tooling stamps](#tooling-stamps). Required; empty `{}` is acceptable for legacy specs.

**Representation is extension-overridable.** The YAML frontmatter shown above is the default. Adopters may declare a different header form (e.g., a prose markdown header) in their extension spec, provided every required field above remains present and the extension declares the mapping (which extension field carries which base field). The capability requires the fields, not the syntactic form. Adding, renaming, or removing required fields is not authorised by this override — only the form changes; the contract does not.

#### Prose body

Required:

- **Objective** — one paragraph. What this project exists to do.
- **Close criterion** — one sentence. How we know the project is done.

Optional (include when applicable):

- **Hypothesis** — when the project is experimental. States what is being tested.
- **Success metrics** — quantitative or qualitative measures of how well the project achieved its objective. Distinct from close criterion: close is binary (did we finish?), metrics are measured outcomes.
- **Output** — description of what the project produces (deliverable, published artefact, changed system state).
- **Related** — links to other specs, decisions, or context.

### Status semantics

- **started** — the project artefact exists but is incomplete. Required fields may be `TBD`. The contributor is still drafting. Default state from [`/new-project`](./new.md).
- **proposed** — the spec has passed the content gate (no `TBD`s, Hypothesis present if experimental, Success metrics declared or excused). The project is **ready to execute**, awaiting governance approval. Execution has not begun.
- **in-progress** — the project has been approved by the appropriate scope's governance and is actively being executed.
- **closed** — the close criterion is met; `closed: YYYY-MM-DD` records the date. The closing audit (Outcome / Hypothesis validation / Migration audit) is complete.
- **cancelled** — the project was halted before reaching `closed`. Reachable from `started`, `proposed`, or `in-progress`. `closed: YYYY-MM-DD` records the cancellation date; the prose body gains a short cancellation note. For `started → cancelled` and `proposed → cancelled`, the closing audit is optional (the project never ran, so most migration categories will be `none`).

Transitions are manual edits to the frontmatter, recorded via the adopting repository's normal operational flow (typically a pull request). Two transitions carry explicit gates: `started → proposed` via the [content gate](#gate-a--started--proposed-content-gate), and `proposed → in-progress` via the [approval gate](#gate-b--proposed--in-progress-approval-gate). Other transitions — `started/proposed/in-progress → cancelled`, and `in-progress → closed` — are content edits authored by the owner; the closing audit applies on close per [Closing a project](#closing-a-project).

### Gate A — Started → Proposed (content gate)

The `started → proposed` flip requires the spec to pass a content check. This is the mechanical readiness gate: it answers *"is this spec ready for governance to look at?"* not *"should we approve this?"*

A project is ready to transition to `proposed` when:

- **All required fields are populated.** No `TBD` in frontmatter (`project`, `status`, `opened`, `owner`); no `TBD` in required prose (Objective, Close criterion).
- **The owner is the requester.** Per [Project initiation](#project-initiation), the person with the need is the named owner before work begins. When the spec was drafted by someone other than the requester, the spec body or an adjacent feedback entry records the requester's explicit sign-off; the owner field still names the requester, not the drafter.
- **Hypothesis is present when the project is experimental.** The field cannot be deferred to "after we start."
- **Success metrics are present, or explicitly declared not applicable.** Either the Success metrics section is populated, or the spec carries the line *"Success metrics: not applicable — <one-sentence rationale>."* Silent omission is not authorised by the gate; the choice to omit must be explicit.

The gate is **content-level**, not process-level. It does not require an approver to sign off; it requires the spec itself to be in a state where signing off would be meaningful.

**Extension-level additions.** When an adopter's extension declares additional required fields, the gate covers them too — the transition is not authorised until those fields are populated. The check runs base + extension together, by the same composition rule as the elicitation flow in [`new.md`](./new.md).

**Enforcement.** A contributor self-check. The [`adherence-check`](../adherence-check/spec.md) capability mechanises the gate via `oos:adhere-to project <slug>`; in `fix-with-me` mode the tool walks the gaps interactively.

### Gate B — Proposed → In-progress (approval gate)

The `proposed → in-progress` flip requires governance approval. This is the question *"should we do this?"*, not *"is the spec complete?"* — Gate A has already answered that.

The approval gate is **deferred to the adopter's [`governance-at-scope`](../governance-at-scope/spec.md)**. At base level, the project capability does not prescribe who approves or how. Adopters declare the approver in their scope's `governance/` folder, in the project's parent module governance, or via the relevant scope's `people.md` lead-table.

When status flips to `in-progress`, the spec records the approval event auditably — either inline (a *"Approved 2026-05-27 by <name>"* note in the prose), via a feedback entry in the project's `feedback.md` linking the approval, or both. The base capability does not prescribe the recording form at v0; the spec must just leave a trail a future reader can follow.

**Self-approval is permitted.** A project with no governance owner — solo contributors, informal teams — is not blocked at Gate B. The contributor self-approves and records the choice: *"Self-approved 2026-05-27, no separate governance scope"* or equivalent. The audit trail still exists; the gate's content just trivially passes.

### Cancellation

A project may be cancelled from any pre-closed state: `started`, `proposed`, or `in-progress`. The status flips to `cancelled`, the `closed: YYYY-MM-DD` field is added with the cancellation date, and the prose body gains a short note explaining why.

- **From `started`** — a draft the contributor decided not to pursue. The closing audit's five categories will mostly be `none`; walk them briefly anyway.
- **From `proposed`** — a complete spec that was never approved (governance declined, or priorities shifted). The closing audit is brief — no execution learnings to migrate, but pain points (*why was this not approved?*) may surface a missing spec elsewhere.
- **From `in-progress`** — execution halted. The closing audit is full per the existing [Closing a project](#closing-a-project) rules.

The cancellation note is one paragraph in the prose body, dated. Format is flexible; the only requirement is that a future reader can answer *"why did this stop?"*

### Closing a project

When a project transitions to `closed` or `cancelled`, the owner performs a **closing audit** before the folder is archived. The audit ensures that what the project produced — learnings, artefacts, open questions — flows to the right place rather than being lost when the folder goes quiet.

**Archive location.** Closed projects move to `projects/closed/<slug>/`. The spec remains; the folder is no longer actively maintained.

**Three required sections**, added to `spec.md` at close:

**Outcome** — 4–6 sentences covering: what the project set out to do, what actually happened, what was not achieved, why it is stopping, and what comes next. Written in the past tense by the owner at close.

**Hypothesis validation** — one line stating whether the hypothesis was validated, refuted, or inconclusive, with the key evidence. Required only when the project declared a Hypothesis; omitted otherwise.

**Migration audit** — a table with one row per thing that emerged during the project and needs a destination. The owner walks five categories; if a category produced nothing, it gets a single `none` row — the category is walked even when empty.

| What emerged | Category | Destination | Action | Destination owner |
|---|---|---|---|---|
| … | … | … | … | … |

**Five categories:**

- **Pain points** — what did not work. Do not migrate the pain point itself; instead identify what spec is missing or what decision is pending that would close the gap. Migrate the missing spec or pending decision.
- **Artefacts** — concrete outputs produced during the project (process specs, prompts, tools, scripts, templates). Destination: the relevant cluster workflow, a shared capability folder, or wherever the artefact will be maintained and consumed.
- **Contexts** — strategic angles, dependencies, or constraints that surfaced and did not exist as a spec at open. Destination: the relevant scope's `context/` folder.
- **Sister projects** — continuations or derived projects already in motion. Action: link; this project does not absorb their work.
- **Capability candidates** — did a reusable pattern emerge? Name the second project that would validate it. Promotion is the infrastructure owner's call, not the closing project owner's.

**Risk disposition audit.** Before a project can transition to `closed` or `cancelled`, all risk records in the project's `risks/` folder must be in a terminal state (`mitigated`, `accepted`, `closed`). Any risk with `status: open` or `status: deferred` blocks project closure. The closing audit must confirm: "all risks resolved or accepted" before the project spec's status is updated. This check only applies when `risk-at-scope` is active.

**Actions available in the audit:**

- **moved** — the content already lives at the destination. Requires the project owner to own the destination, or the destination owner to have given explicit consent.
- **pointed** — the content stays in the project folder and the destination spec links to it.
- **flagged for destination owner** — the project owner names the need but does not edit the other spec. The row signals the destination owner; they decide whether to absorb it.
- **none** — category walked; nothing emerged.

### Tooling stamps

Every project spec carries a `tooling` frontmatter block recording the state-changing tools that have written to it. The block is required; an empty `tooling: {}` is acceptable for specs predating 2026-05-27 and emits a `warning` (not a gap) from [`adherence-check`](../adherence-check/spec.md).

**Schema (per tool entry):**

```yaml
tooling:
  oos:new project:    # tool that scaffolded this spec
    first: 2026-05-08
    by: Jordan Lee
  oos:adhere-to:      # tool that has run against this spec since
    first: 2026-05-08
    last: 2026-05-27  # omitted when equal to first
    by: Jordan Lee # most recent invoker
```

**Field semantics.**

- `first` — date of first invocation against this file. Always present.
- `last` — date of most recent invocation, present only when it differs from `first`.
- `by` — full name of the most recent invoker (from `git config user.name` at run time).

**Which tools stamp.** State-changing tools that write to the file — for example, `oos:new project` on scaffold, `oos:adhere-to` in `fix-with-me` mode, and any adopter-extension tool that modifies project specs. Read-only tools (e.g., `oos:catchup`) do not stamp; their adoption is measured separately.

**Why first-use plus last-use.** First-use answers the adoption question (*"did this tool ever run?"*). Last-use answers the staleness question (*"is the adherence-check data current?"*). Invocation count is omitted — aggregate counts are answered by grep across the repo, not by per-file state.

**Authority.** A tool that writes to a project spec must update the `tooling` block in the same write. Tools that modify a spec without stamping emit a `warning` finding from `adherence-check`. See the [tool stamping principle](../tooling/spec.md#tool-stamping-state-changing-tools) for the cross-capability rule.

## Project initiation

**The person with the need authors the spec.** A project spec is not a work order issued to an implementor — it is the requestor's articulation of the problem, why it matters, and what done looks like. When a stakeholder asks a contributor to build something, the spec should be written by the stakeholder, not transcribed from a conversation by the contributor who will implement it.

This matters for two reasons:

1. **Traceability.** A spec authored by the requestor captures *why* the project exists in their own words. A spec assembled by the implementor from a conversation captures *what was said*, which is not the same thing. When a project is reviewed weeks or months later — was this useful? did it solve the problem? should we do more of this? — the spec is the primary evidence. If the why is missing or inferred, the review cannot close the loop.

2. **Ownership.** Writing the spec is part of the requestor's job, not a formality to be done for them. An implementor who writes the spec on the requestor's behalf does part of the requestor's job and takes on accountability that belongs to the requestor. Over time, this pattern moves ownership of the problem away from the people who have it.

**What implementors should do when they receive a conversational request.** Route the request back to the requestor: ask them to open a spec (or a feedback entry in the relevant scope's inbox) describing the need in their own words. The implementor may offer to draft a starting point for the requestor's review and explicit sign-off — but the requestor is the named owner before work begins, not after.

A project that starts from a conversational request without a spec is outside this pattern. The spec is the signal that the requestor has committed to the need being worth tracking.

**Reviewing whether requests were worth it.** Because every project has a spec authored by the requestor, the adopter can periodically review who asked for what and whether the resulting project was useful. This is the mechanism that lets an organisation challenge the originator of a need — not on the basis of memory or conversation logs, but on the basis of the spec and the close criterion the requestor wrote.

## What this capability is not

- **A workflow for changing the project schema.** Changes to *this capability* (the `project` schema) go through `capability-lifecycle`. Project artefacts themselves are operational content, not normative content of the standard.
- **A mandate on every piece of time-bound work.** Adopters may run informal work outside this capability. Conformance is opt-in, per the standard's general principle.
- **A task tracker.** The spec describes purpose, status, and outcome. Day-to-day task management lives outside — adopter tools, issue trackers, or an adopter-level extension capability.
- **A governance surface.** Approval, review, and gate decisions for a project are governance concerns at the adopter's scope, covered by `governance-at-scope`.

## Not prescribed

- **Contents of success metrics.** Adopters write whatever is meaningful for their project (percentage lifts, completion rates, qualitative descriptions). The capability requires the section when success metrics are being recorded; it does not prescribe their contents.
- **Relationship to clusters, teams, or other organisational structures.** An adopter's project may reference a cluster or a team; the standard does not require any such reference.
- **Auxiliary files.** Some adopter projects carry `tasks.md`, `updates.md`, `feedback.md`, or `origin.md`. These are adopter choices; the capability defines `spec.md` only.
- **Alternate folder names.** v0 prescribes `projects/`. Adopters with a different existing convention (e.g., `initiatives/`) are not in conformance at v0; a later proposal may add folder-name override.
- **Contents of the migration audit rows.** The five categories are prescribed; the specific destinations and actions within each category are the project owner's judgment call.
- **Approval or review gates.** Whether a project needs approval before transitioning from `proposed` to `in-progress` is a governance concern at the adopter's scope.

## Rationale

Two choices shaped the minimum:

1. **One shape for experiment and execution.** Adopters run both. Splitting into two capabilities (experiment vs execution) would force every adopter to categorise when the difference is often a matter of degree — most projects have *some* hypothesis and *some* deliverable. Optional fields handle the variation without a category choice.
2. **Ownership schema reused from `governance-at-scope`.** Before this capability, an adopter's projects may use prose ownership while governance uses structured frontmatter. Reusing the governance owner shape resolves the drift before it spreads to future concept capabilities (team, etc.).

## Invocation

See [`new.md`](./new.md) for the command that scaffolds a new project spec.

## Related

- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — source of the shared `owner` schema.
- [`../capability-lifecycle/spec.md`](../capability-lifecycle/spec.md) — the workflow through which this capability was added and through which future changes to its shape go.
- [`../adherence-check/spec.md`](../adherence-check/spec.md) — will validate conformance of project specs once extended to cover the `project` capability.
