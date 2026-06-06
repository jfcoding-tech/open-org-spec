# Risk Scanner

**Owner:** Javier Fernandez
**Status:** Active

The risk scanner reads the risk registry and routes a disposition request to each risk owner's scope `feedback.md` when a risk has breached its escalation threshold. It is the operational complement to the risk registry: the registry aggregates the picture; the scanner acts on it.

This is a **Case B standard capability agent** — no project spec required. The capability spec (`spec.md`) is the governance artefact.

---

## Purpose

A risk that has sat `open` past its `escalation_threshold` without disposition is a governance gap. The scanner closes that gap by surfacing it to the owner through the feedback-inbox they already read — the same channel used by `decision-escalation`. No new process, no new surface: the owner sees the disposition request in their normal catchup flow.

---

## Pattern

### Step 1 — Read the registry

Read the adopter-declared risk registry file. Parse all risk entries where `status: open`.

If the registry is absent or stale (generated more than 25 hours ago): do not run. Log a warning to the adopter-declared warnings file and stop. The scanner depends on a fresh registry; running against a stale one would produce incorrect escalations.

### Step 2 — Identify risks requiring escalation

For each `open` risk in the registry, evaluate:

- **Breach check:** `age_days ≥ escalation_threshold` → the risk is RED and requires escalation
- **Dedup check:** look in the scope's `feedback.md` for an existing entry from this scanner referencing the same `id` within the last `dedup_window` days. If found, skip — the owner has already been notified and the clock is running.

A risk that has been breached AND has no recent dedup entry is eligible for escalation.

### Step 3 — Write disposition requests

For each eligible risk, write a disposition request entry to the scope's `feedback.md`:

```
## YYYY-MM-DD | risk-scanner → <owner> — Risk awaiting disposition: <id>

[risk-scanner] `<id>` (`<title>`) has been `open` for <age_days> days — past its
<escalation_threshold>-day escalation threshold. Current RAG: RED.

Please confirm one disposition:
- **Confirm with date** — you are actively working to resolve it; provide an updated `disposition_at` and expected close date.
- **Defer with reason** — you are choosing to park this risk; provide a rationale and a review trigger date.
- **Reassign** — the owner is wrong; state who should hold it and it will be rerouted.

→ <owner>

---
```

If the risk has multiple owners, write a separate entry addressed to each owner in their respective scope's `feedback.md`.

If the target `feedback.md` does not exist, create it with a minimal two-line header before appending.

### Step 4 — Log invocation

Append to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | /risk-scanner | files_read: N | catalogue_assisted: true | outcome: success/fail | spec_version: <version>
```

`catalogue_assisted: true` because the scanner reads the risk registry (the risk catalogue) rather than walking `risks/` folders directly.

---

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Registry path | Path to the risk registry file | *(required)* |
| Invocation log path | Shared invocation log | *(required)* |
| Warnings file | Where to log registry-absent warnings | *(required)* |
| Dedup window | Days before re-escalating the same risk | 14 days |
| Scope→feedback routing | Table mapping risk scope paths to feedback file targets | *(required)* |

---

## Scheduling

Daily, after the risk registry agent. The scanner must always operate on a fresh registry — schedule it immediately after the registry run in the same workflow or with a short gap.

---

## Related

- [`spec.md`](./spec.md) — risk-at-scope capability; escalation contract and disposition frame
- [`registry.md`](./registry.md) — risk registry agent; builds the registry this scanner reads
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — the inbox conventions used for disposition requests
