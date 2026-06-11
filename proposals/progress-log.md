---
change: progress-log
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: progress log capability

## Intent

Add a `progress-log` capability to the standard. A progress log is a dated, append-only file (`updates.md`) co-located with a scope that records what was worked on, why, and where things stand — written at the moment of delivery, not as a separate reporting exercise. The capability applies to any scope that produces ongoing work: a project, a function, a cluster, a module.

## Rationale

**Organisations struggle with update fatigue because reporting is separated from delivery.** The standard model for progress visibility is a status update written after the work is done — a separate task requiring the contributor to context-switch, reconstruct what happened, and produce a document nobody was watching them write. By the time the update arrives, it is stale. Contributors deprioritise it. Stakeholders stop trusting it. The org loses visibility into what is actually moving.

**The problem is structural, not behavioural.** Asking contributors to report more reliably does not fix the root cause. The root cause is that reporting is an additional deliverable rather than a by-product of the work itself. As long as it remains separate, it will always compete with the work for time and attention — and the work will win.

**A progress log collapses delivery and documentation into the same act.** When a contributor finishes a piece of work, they write a dated entry: what moved, why, and where things stand. This is not a summary produced after the fact — it is the natural last step of completing the work, written while the context is live. The discipline required is minimal: one entry per session or significant milestone. The by-product is a running log that any stakeholder can read to know the current state of the scope without asking.

**Co-location is what makes it work.** The log lives in the same folder as the spec it describes. A stakeholder reading the spec can read the log in the same motion. There is no separate reporting system to navigate, no dashboard to check, no meeting to attend. The information is where the work is.

**It is distinct from every other artifact in the standard.** `decisions/` records what was formally decided. `risks/` records what threatens the scope. `feedback.md` captures observations from others. `spec.md` describes what the scope is, atemporally. None of these answer the question a stakeholder actually asks: *what happened here recently, and where does it stand right now?* The progress log answers that question and nothing else.

**The pattern applies to any scope that produces ongoing work.** It is not specific to projects. A function accumulating decisions and interfaces, a module evolving its capabilities, a cluster running a continuous programme — all produce ongoing work that stakeholders need visibility into. The artifact is the same; the scope varies.

## Delta

New capability spec at `specs/progress-log/spec.md`. No changes to existing capability specs.

The spec defines:

**The artifact.** A single file named `updates.md` at the scope root. Append-only — entries are never edited or removed after writing. New entries are prepended (most recent first).

**Entry shape.** Each entry is a dated section (`## YYYY-MM-DD`) containing one or more named sub-sections. Each sub-section records:
- **What was done** — the work that moved, linked to deliverables where they exist
- **Why** — the trigger or rationale; why this work happened now
- **Current status** — where things stand at the end of this entry; what is open, what is blocked

Entries are written at the moment of delivery — when the work is complete or at a significant milestone — not as a retrospective summary.

**What belongs in an entry.** Work done at this scope in this session or milestone period. Decisions made, artifacts created or updated, blockers encountered, dependencies surfaced. Links to the artifacts produced.

**What does not belong.** Opinions, predictions, status theatre. If nothing moved, no entry is written. The log is a state record, not a performance. An entry that says "still working on it" with no new information is not an entry.

**Ownership.** The scope owner is responsible for the log's currency. Contributors who do work at the scope may write entries; the scope owner ensures entries are not stale relative to the actual work. A log with no entry in the past 30 days on an active scope is a signal worth investigating.

**Header.** The file carries a brief header: owner, current status of the scope, purpose (one line), and a link to the scope's `spec.md`. The header is updated when the scope's status changes; entries below it are never edited.

**Conformance check for `/adhere-to progress-log`.** The tool checks:
- `updates.md` exists at the scope
- The header is present and carries owner, status, and a link to the spec
- At least one entry exists if the scope status is `active`
- No entry is older than 30 days on a scope whose status is `active` (warning, not blocker)

## Acceptance scenarios

### IC documents work as a by-product of delivery

Given a contributor who has just completed a piece of work at a scope
When they write a dated entry in `updates.md` describing what moved, why, and current status
Then a stakeholder reading the log can understand the scope's current state without asking the contributor
And no separate reporting task is required — the entry is the last step of the work itself

### Stakeholder reads the spec and the log in the same motion

Given a stakeholder navigating to a scope's folder
When they open `spec.md` (what the scope is) and `updates.md` (what has been happening)
Then they have a complete picture of the scope: its mandate, its current state, and recent progress
And they have not needed to attend a meeting, check a dashboard, or ask the owner

### Log is distinct from decisions, risks, and feedback

Given a scope with `decisions/`, `risks/`, `feedback.md`, and `updates.md` all present
When a contributor wants to record a formal decision
Then it goes in `decisions/` — not in `updates.md`
When a contributor wants to flag a threat
Then it goes in `risks/` — not in `updates.md`
When a contributor wants to surface an observation for the owner
Then it goes in `feedback.md` — not in `updates.md`
When a contributor wants to record what they worked on and where things stand
Then it goes in `updates.md` — not in any of the others

### No entry on an active scope surfaces as a warning

Given a scope with `status: active` and no entry in `updates.md` in the past 30 days
When `/adhere-to progress-log` is run
Then a warning is routed to the scope owner's feedback inbox noting that the log has gone stale

### Progress log applies to non-project scopes

Given a function scope (not a project) with ongoing work
When the function owner activates the `progress-log` capability at their scope
Then `updates.md` is created and the same entry shape and ownership rules apply
And the capability does not require the `project` capability to be active

## Related

- `specs/project/spec.md` — the progress log is useful at project scope but is not limited to it
- `specs/feedback-inbox/spec.md` — sibling artifact at the same scope; different concern
- `specs/governance-at-scope/spec.md` — decisions belong in `decisions/`, not in the log
- `specs/observability/spec.md` — the progress log is human-authored signal; observability is machine-authored signal; both contribute to scope visibility
