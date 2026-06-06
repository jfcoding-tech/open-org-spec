# Spec-Health: Decision-Nudge Agent

**Owner:** Javier Fernandez
**Status:** Active

Part of the [spec-health suite](../spec.md). Scans all decision records in the repo for entries with open or proposed status that have received no commits in more than N days, and writes a dated nudge to the owning scope's feedback inbox.

## Purpose

Decision records marked open or proposed are regularly left without a resolution path because no one is watching the clock. A lightweight automated nudge, addressed to the decision owner and written into the feedback inbox the owner already reads, closes the gap between "decision filed" and "decision resolved" without requiring a new process or a separate task tracker.

## Inputs

- Decision folder paths (extension point — where to look for decision records)
- Open-status vocabulary (extension point — which status values indicate an unresolved decision)
- Resolved-status vocabulary (extension point — which values indicate a decision is closed)
- Staleness threshold (extension point — days of inactivity before a decision is considered stale, default 7)
- Dedup window (extension point — days before re-nudging the same decision, default 14)
- Scope-to-feedback-inbox routing (extension point)

## Pattern

### Step 1 — Walk decision folders

Walk all adopter-declared decision folder paths. Collect every decision record found. Exclusions: template files, README files.

### Step 2 — Classify status

For each decision file, read the first 20 lines. Extract the value of `**Status:**` or `Status:` (case-insensitive). A decision is considered open if:

- No status field is present, or
- The extracted value matches the adopter's open-status vocabulary.

Skip the file if the extracted value matches the resolved-status vocabulary.

### Step 3 — Check staleness

For each open decision, determine when it last received any change. If the last change date is within the staleness threshold (default 7 days), skip — the decision is in active flight.

### Step 4 — Dedup check

Before writing a nudge, check whether the target feedback inbox already contains an entry from this agent referencing the same decision path with a date within the dedup window (default 14 days). If yes, skip. This prevents weekly re-nudging of the same stale decision while still prompting after the window if it remains unresolved.

### Step 5 — Write nudge entry

For each stale open decision that passes the dedup check, append a nudge entry to the target feedback inbox:

```
## YYYY-MM-DD | decision-review-nudge → <owner> — Stale proposed decision: <filename>

[decision-review-nudge] `<path>` has been in `<status>` status for <N> days with no commits.
Owner: <owner>. If this decision is resolved, update its Status field. If it is still open,
note the blocker or extend the review date.

→ <owner>

---
```

If the target feedback inbox does not exist, create it with a minimal two-line header before appending.

### Step 6 — Log invocation

Implements the observability contract per the [suite spec](../spec.md#observability-contract). Append one entry to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | decision-review-nudge | files_read: N | catalogue_assisted: false | outcome: success/fail
```

`catalogue_assisted: false` — this agent walks decision folders directly; it does not read the catalogue.

### Implements shared contracts

This agent implements the retry contract and observability contract per the [suite spec](../spec.md#shared-contracts).

## Data contracts

**Nudge entry format** (written to feedback inbox):

```
## YYYY-MM-DD | decision-review-nudge → <owner> — Stale proposed decision: <filename>

[decision-review-nudge] `<path>` has been in `<status>` status for <N> days with no commits.
Owner: <owner>. If this decision is resolved, update its Status field. If it is still open,
note the blocker or extend the review date.

→ <owner>

---
```

**Invocation log entry format** (per suite spec):

```
YYYY-MM-DD HH:MM UTC | decision-review-nudge | files_read: N | catalogue_assisted: false | outcome: success/fail
```

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Decision folder paths | Where to look for decision records | *(required)* |
| Open-status vocabulary | Status values that mean unresolved | `proposed`, `draft`, `open`, `pending` |
| Resolved-status vocabulary | Status values that mean closed | `accepted`, `decided`, `superseded`, `closed`, `archived` |
| Staleness threshold | Days of inactivity before a decision is stale | 7 days |
| Dedup window | Days before re-nudging the same decision | 14 days |
| Nudge entry format | Override the default nudge entry template | Default format above |
| Scope→feedback-inbox routing | Table mapping decision path patterns to feedback file targets | *(required)* |

## Rationale

The staleness threshold is intentionally short (default 7 days). Decisions that are genuinely in active flight receive regular commits; those that have gone quiet have usually stalled without an explicit acknowledgement. A weekly nudge into the feedback inbox the owner already reads is lower friction than a task tracker ticket and higher signal than a recurring calendar reminder.

## Related

- [`../spec.md`](../spec.md) — suite spec; shared contracts (scheduling, retry, observability)
- [`../implementations/README.md`](../implementations/README.md) — runtime contract
