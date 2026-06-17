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

### Step 3 — Log conformance check

For each risk in the registry where `status` is not `closed` or `resolved`:

1. Read the risk file body from disk.
2. Check that a `## Log` section exists.
3. If `disposition_at` is set: parse `### YYYY-MM-DD —` heading lines in the `## Log` section and check that at least one matches `disposition_at` exactly.

Write a conformance request to the resolved `feedback.md` (using the same routing logic as Step 4) for each violation found:

- **`[log-absent]`** — the `## Log` section is missing entirely. Entry text: "`<id>` (`<title>`) has no `## Log` section. Add a `## Log` section with a dated entry for each disposition action."
- **`[log-missing]`** — `disposition_at` is set but no `## Log` entry exists for that date. Entry text: "`<id>` (`<title>`) has `disposition_at: <date>` but no `## Log` entry dated `<date>`. Add a `### <date> — <author> — <change type>` entry explaining what was decided."

Apply the same dedup logic as Step 2: if a `[log-absent]` or `[log-missing]` entry for this risk already exists in the target `feedback.md` within the dedup window, skip.

`closed` and `resolved` risks are exempt — their log is frozen and not validated.

### Step 4 — Resolve routing target

Before writing, determine which `feedback.md` to route the disposition request to:

**For risks whose file lives under a scoped folder (`clusters/`, `functions/`, `projects/`, etc.):**

1. Read `scope` from the risk record frontmatter.
2. If `scope` is present, look it up in `governance/catalogue/scopes.yaml` to get `feedback_inbox`, and route there addressed to `risk.owner`.
3. If `scope` is absent, fall back to path inference: use the `feedback.md` nearest to the risk file's parent folder.

**For risks whose file lives under `risks/` (repo root / programme risks):**

1. Read `scope` from the risk record frontmatter. This field is **required** for programme risks.
2. Look up `scope` in `governance/catalogue/scopes.yaml` to get `feedback_inbox`. Route the escalation entry to that inbox, addressed to `risk.owner`.
3. If `scope` is absent on a programme risk: log a `[scope-missing]` warning to the adopter-declared warnings file and route to `governance/feedback.md` instead.
4. If `scope` is present but does not resolve in `governance/catalogue/scopes.yaml`: log a `[scope-not-found]` warning and route to `governance/feedback.md` instead.

**Routing table summary:**

| Risk file location | Routing |
|---|---|
| `clusters/`, `functions/`, `projects/`, etc. | `scope` field → `governance/catalogue/scopes.yaml` → `feedback_inbox`; fall back to path inference if `scope` absent |
| `risks/` (repo root) | Resolved from `risk.scope` via `governance/catalogue/scopes.yaml` — required; fall back to `governance/feedback.md` with `[scope-unresolved]` warning if absent or not found in registry |

### Step 5 — Write disposition requests

For each eligible risk, write a disposition request entry to the resolved `feedback.md`:

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

If the risk has multiple owners, write a separate entry addressed to each owner in their respective resolved `feedback.md`.

If the target `feedback.md` does not exist, create it with a minimal two-line header before appending.

### Step 6 — Log invocation

Append to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | /risk-scanner | files_read: N | catalogue_assisted: true | outcome: success/fail | spec_version: <version>
```

`catalogue_assisted: true` because the scanner reads the risk registry (the risk catalogue) rather than walking `risks/` folders directly. `files_read` counts the registry file plus each individual risk file read during the log conformance check (Step 3).

---

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Registry path | Path to the risk registry file | *(required)* |
| Invocation log path | Shared invocation log | *(required)* |
| Warnings file | Where to log registry-absent warnings | *(required)* |
| Dedup window | Days before re-escalating the same risk | 14 days |
| Scope catalogue path | Path to `governance/catalogue/scopes.yaml` — used to resolve `risk.scope` → `feedback_inbox` for programme risks and optionally for scoped risks | *(required)* |
| Scope→feedback fallback | Inbox used when `scope` is absent or unresolvable on a programme risk | `governance/feedback.md` |

---

## Scheduling

Daily, after the risk registry agent. The scanner must always operate on a fresh registry — schedule it immediately after the registry run in the same workflow or with a short gap.

---

## Related

- [`spec.md`](./spec.md) — risk-at-scope capability; escalation contract and disposition frame
- [`registry.md`](./registry.md) — risk registry agent; builds the registry this scanner reads
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — the inbox conventions used for disposition requests
- `governance/catalogue/scopes.yaml` — scope catalogue; maps scope identifiers to `feedback_inbox` paths used for routing programme risks
