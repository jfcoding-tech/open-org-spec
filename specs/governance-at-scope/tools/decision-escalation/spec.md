# Decision-escalation

**Owner:** Javier Fernandez
**Status:** Active

A governance maintenance tool of the [`governance-at-scope`](../../spec.md) capability. Scans all `decisions/` folders for open decisions past the staleness threshold and routes a disposition request to the owning scope's `feedback.md` using the standard disposition frame: *Confirm with date / defer with reason / reassign.*

## Purpose

Decision records marked open or proposed are regularly left without a resolution path because no one is watching the clock. `governance-at-scope` requires each scope's decisions to reach a resolved state with a `decided_at` date, but nothing surfaces a decision that has gone quiet. A lightweight automated escalation, addressed to the decision owner and written into the feedback inbox the owner already reads, closes the gap between "decision filed" and "decision dispositioned" without requiring a new process or a separate task tracker.

This is a governance maintenance tool, not part of the spec-health suite. It belongs to `governance-at-scope` because what it enforces — that open decisions are driven to disposition — is a governance discipline declared by that capability (the `decided_at` rule and the decision record schema).

## Inputs

- Decision folder paths (extension point — where to look for decision records)
- Open-status vocabulary (extension point — which status values indicate an unresolved decision)
- Resolved-status vocabulary (extension point — which values indicate a decision is closed)
- Staleness threshold (extension point — days of inactivity before a decision is considered stale, default 7)
- Dedup window (extension point — days before re-escalating the same decision, default 14)
- Scope-to-feedback-inbox routing (extension point)

## The disposition frame

When a decision is found stale, the escalation does not merely nudge — it requests a **disposition**, presenting the owner three explicit options:

- **Confirm with date** — the decision is in fact resolved; record `decided_at` and update the status.
- **Defer with reason** — the decision is genuinely still open; note the blocker and extend the review date.
- **Reassign** — the named owner is not the right person to drive this; route it to whoever is.

Routing a disposition request rather than a bare reminder forces the open decision toward one of three closed states, which is what `governance-at-scope`'s `decided_at` discipline ultimately requires.

## Pattern

### Step 1 — Walk decision folders

Walk all adopter-declared decision folder paths. Collect every decision record found. Exclusions: template files, README files. When the [catalogue](../../../tooling/catalogue/spec.md) capability is active, this tool MAY read `decisions.yaml` directly instead of walking the folders — that sub-file holds the decision entries this tool needs.

### Step 2 — Classify status

For each decision file, read the first 20 lines. Extract the value of `**Status:**` or `Status:` (case-insensitive). A decision is considered open if:

- No status field is present, or
- The extracted value matches the adopter's open-status vocabulary.

Skip the file if the extracted value matches the resolved-status vocabulary.

### Step 3 — Check staleness

For each open decision, determine when it last received any change. If the last change date is within the staleness threshold (default 7 days), skip — the decision is in active flight.

### Step 4 — Dedup check

Before writing a disposition request, check whether the target feedback inbox already contains an entry from this tool referencing the same decision path with a date within the dedup window (default 14 days). If yes, skip. This prevents weekly re-escalation of the same stale decision while still prompting after the window if it remains unresolved.

### Step 5 — Write disposition request

For each stale open decision that passes the dedup check, append a disposition request to the target feedback inbox:

```
## YYYY-MM-DD | decision-escalation → <owner> — Stale open decision: <filename>

[decision-escalation] `<path>` has been in `<status>` status for <N> days with no commits.
Owner: <owner>. Please disposition:
  - Confirm with date — record `decided_at` and update Status if it is in fact resolved.
  - Defer with reason — note the blocker and extend the review date if it is still open.
  - Reassign — route to the right owner if it is not yours to drive.

→ <owner>

---
```

If the target feedback inbox does not exist, create it with a minimal two-line header before appending.

### Step 6 — Log invocation

Append one entry to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | decision-escalation | files_read: N | catalogue_assisted: true/false | outcome: success/fail
```

`catalogue_assisted: true` when the tool read `decisions.yaml` rather than walking decision folders directly.

## Data contracts

**Disposition request format** (written to feedback inbox):

```
## YYYY-MM-DD | decision-escalation → <owner> — Stale open decision: <filename>

[decision-escalation] `<path>` has been in `<status>` status for <N> days with no commits.
Owner: <owner>. Please disposition:
  - Confirm with date — record `decided_at` and update Status if it is in fact resolved.
  - Defer with reason — note the blocker and extend the review date if it is still open.
  - Reassign — route to the right owner if it is not yours to drive.

→ <owner>

---
```

**Invocation log entry format:**

```
YYYY-MM-DD HH:MM UTC | decision-escalation | files_read: N | catalogue_assisted: true/false | outcome: success/fail
```

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Decision folder paths | Where to look for decision records | *(required)* |
| Open-status vocabulary | Status values that mean unresolved | `proposed`, `draft`, `open`, `pending` |
| Resolved-status vocabulary | Status values that mean closed | `accepted`, `decided`, `superseded`, `closed`, `archived` |
| Staleness threshold | Days of inactivity before a decision is stale | 7 days |
| Dedup window | Days before re-escalating the same decision | 14 days |
| Disposition request format | Override the default request template | Default format above |
| Scope→feedback-inbox routing | Table mapping decision path patterns to feedback file targets | *(required)* |

## Rationale

The staleness threshold is intentionally short (default 7 days). Decisions that are genuinely in active flight receive regular commits; those that have gone quiet have usually stalled without an explicit acknowledgement. Routing a disposition request — rather than a bare reminder — into the feedback inbox the owner already reads is lower friction than a task tracker ticket and higher signal than a recurring calendar reminder, and it forces the decision toward the resolved state with a `decided_at` date that `governance-at-scope` requires.

## Related

- [`../../spec.md`](../../spec.md) — the governance-at-scope capability; the decision record schema and `decided_at` discipline this tool enforces.
- [`../../../tooling/catalogue/spec.md`](../../../tooling/catalogue/spec.md) — the catalogue capability; `decisions.yaml` is this tool's optional fast-path data source.
- [`../../../feedback-inbox/spec.md`](../../../feedback-inbox/spec.md) — the inbox convention this tool writes disposition requests into.
