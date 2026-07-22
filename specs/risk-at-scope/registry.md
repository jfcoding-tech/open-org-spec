# Risk Registry

**Owner:** Javier Fernandez
**Status:** Active

The risk registry agent walks all `risks/` folders across governed scopes, aggregates every risk record into a machine-readable registry file, and writes a delta log of what changed since the previous run. It is the catalogue equivalent for `risk-at-scope`.

This is a **Case B standard capability agent** — no project spec required. The capability spec (`spec.md`) is the governance artefact.

---

## Purpose

Distributed risk records in scope-level `risks/` folders are invisible unless aggregated. The registry agent provides a single queryable view across all scopes — enabling the stakeholder report's Risk health section, the risk scanner's escalation logic, and any adopter tooling that needs a cross-scope risk picture without walking the full repo.

---

## Pattern

### Step 1 — Delta gate

Read the adopter-declared invocation log. Find the timestamp of the last successful registry run. Use `git log --since="<timestamp>" --name-only -- '**/risks/*.md'` to build a reduced file list of risk records changed since the last run.

If no prior run exists (first-ever execution), or if the log is absent: fall back to a full walk (skip to Step 2 without delta filtering).

### Step 2 — Walk risk records

Walk all `risks/YYYY-MM-DD-*.md` files in:
- `risks/` — programme-level (repo root)
- `<scope>/risks/` — any scope with a `risks/` folder

Exclusions: `projects/closed/` (closed projects are guaranteed to have only terminal-state risks).

For delta runs: walk only the files identified in Step 1 plus any file whose `id` appears in the existing registry with `status: open` or `status: monitoring` (these risks must be re-evaluated even if the file did not change, because `rag` is derived from the current date vs `escalation_threshold` or `disposition_at`).

### Step 3 — Extract and derive fields

For each risk file, extract:
- `id` — the `R-NNN` identifier
- `title` — short label
- `status` — `open | monitoring | deferred | mitigated | accepted | closed`
- `owner` — named person(s)
- `escalation_threshold` — days
- `disposition_at` — date of last disposition (ISO)
- `related` — links to projects/decisions
- `scope` — inferred from file path (e.g. `projects/agentic-coach-phase-3`)

Derive:
- `rag` — computed from `status`, filename date, `disposition_at`, and `escalation_threshold`:
  - `GREEN` if status is terminal (`mitigated | accepted | closed`) or `deferred`, OR `status: open` with age < 50% of threshold, OR `status: monitoring` with days since `disposition_at` < 50% of threshold
  - `AMBER` if (`status: open` OR `status: monitoring`) with staleness between 50% and 100% of threshold. For `open`, staleness = age (days since filename date). For `monitoring`, staleness = days since `disposition_at`.
  - `RED` if staleness ≥ threshold OR `status: open` with no `disposition_at` in last 14 days

### Step 4 — Update registry

Write the full registry to the adopter-declared registry path. Format:

```yaml
---
generated: YYYY-MM-DDTHH:MM:00Z
tool: risk-registry
period_days: 1
key_metrics:
  open_risks: N
  monitoring_risks: N
  deferred_risks: N
  red_risks: N
  amber_risks: N
  unowned_risks: N
  awaiting_disposition: N
---

risks:
  - id: R-001
    title: <title>
    status: open
    rag: RED
    owner: <name>
    scope: <scope path>
    escalation_threshold: 14
    disposition_at: YYYY-MM-DD
    age_days: N
    related:
      - <relative path>
```

For delta runs: merge the new/updated entries into the existing registry. Preserve unchanged entries. Remove entries whose source file no longer exists.

### Step 5 — Write delta log

Append to the adopter-declared delta log (append-only, never overwrite):

```
## YYYY-MM-DD HH:MM UTC

New: R-025 (Efficiency ROI double-edge) — owner: Felix, status: open, rag: AMBER
Changed: R-003 (Data pipeline SLA) — rag: GREEN→RED, age_days: 14
Closed: R-020 (May 31 delivery target) — decided_at: 2026-06-06
```

If no changes: write a single line: `## YYYY-MM-DD HH:MM UTC — no changes`

### Step 6 — Log invocation

Append to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | /risk-registry | files_read: N | catalogue_assisted: false | outcome: success/fail | spec_version: <version>
```

---

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Registry path | Where to write the aggregated registry | *(required)* |
| Delta log path | Where to append the change log | *(required)* |
| Invocation log path | Shared invocation log | *(required)* |
| Scope exclusions | Paths to exclude from the walk | `projects/closed/` |
| Awaiting-disposition threshold | Days without `disposition_at` before flagging | 14 days |

---

## Scheduling

Daily. The registry agent runs before the risk scanner so the scanner always operates on a fresh registry. Adopter declares the schedule in their manifest.

For the governance-monitor daily workflow: run after `decision-health` so the risk picture is complete before any escalation routing.

---

## Related

- [`spec.md`](./spec.md) — risk-at-scope capability; risk record schema and lifecycle
- [`scanner.md`](./scanner.md) — risk scanner agent; routes escalation requests based on this registry
- [`new.md`](./new.md) — `/new-risk` command; suggests next R-NNN from this registry
