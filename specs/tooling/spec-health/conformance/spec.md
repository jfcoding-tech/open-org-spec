# Spec-Health: Conformance Agent

**Owner:** Javier Fernandez
**Status:** Active

Part of the [spec-health suite](../spec.md). Scans all specs under each active capability's governed scope, detects missing required fields, and writes a dated nudge entry to the owning scope's feedback inbox.

## Purpose

Specs drift from required structure over time. Contributors author content under time pressure and rely on memory for required fields. An automated daily check, addressed to the spec's owner and written into the feedback inbox the owner already reads, closes the gap between "spec created" and "spec conformant" without requiring a separate review process.

## Inputs

- Active capability source (extension point — where the list of active capabilities and their governed scopes is declared)
- Required fields per spec type (extension point)
- Scope-to-feedback-inbox routing table (extension point)

## Pattern

### Execution optimisations

**Delta mode (fast-path for subsequent runs).** Before walking all governed specs, read the adopter's invocation log and find the timestamp of the last successful conformance run. Use `git log --since="<timestamp>" --name-only` filtered to governed spec paths to build a reduced file list. Only walk specs that changed since that run, plus any spec with no prior conformance record. On the very first run, or if the log is absent, fall back to a full walk.

**Parallel scope execution.** Steps 2–4 (walk, check, dedup) are independent per governed scope. Implementations SHOULD process each scope as a separate subagent running concurrently. Step 5 (write nudge entries) runs after all scope subagents complete, serially, to avoid concurrent writes to shared feedback.md files.

### Step 1 — Read active capabilities

Read the adopter-declared active capability source. Extract the list of active capabilities and, for each, the governed scope (the folder tree or file pattern the capability applies to).

### Step 2 — Walk governed specs

For each active capability, walk every spec file under the capability's governed scope. Exclusions (apply repo-wide unless the adopter overrides): `README.md`, `TEMPLATE.md`, `CLAUDE.md`, `feedback.md`, and any file under `context/` or `closed/`.

### Step 3 — Check required fields

For each spec file, extract the required fields defined for its capability type. A spec is non-conformant if any required field is absent, empty, or contains only a placeholder (e.g., `TBD`, `—`, `N/A`).

Default required fields across all spec types:

- `Owner` (or `**Owner:**`)
- `Status` (or `**Status:**`)
- `Purpose` (or an equivalent section — `Objective` for lifecycle specs)
- `Related` links

Additional required fields per spec type are defined in each capability's spec in the standard.

### Step 4 — Dedup check

Before writing a nudge, check whether the target feedback inbox already contains an entry from this agent referencing the same spec path with a date within the dedup window (default 14 days). If yes, skip. This prevents daily re-nudging of the same gap while still prompting after the window if the gap remains unresolved.

### Step 5 — Write nudge entry

For each non-conformant spec that passes the dedup check, append a nudge entry to the scope's feedback inbox:

```
## YYYY-MM-DD | conformance → <owner> — Non-conformant spec: <path>

[conformance] `<path>` is missing required field(s): <field list>.
These fields are required by the `<capability>` capability. Please add them.

→ <owner>

---
```

If the target feedback inbox does not exist, create it with a minimal two-line header before appending.

### Step 6 — Log invocation

Implements the observability contract per the [suite spec](../spec.md#observability-contract). Append one entry to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | conformance | files_read: N | catalogue_assisted: true | outcome: success/fail
```

`catalogue_assisted: true` when the active capability source is the catalogue rather than raw filesystem walking.

### Implements shared contracts

This agent implements the retry contract and observability contract per the [suite spec](../spec.md#shared-contracts).

## Data contracts

**Nudge entry format** (written to feedback inbox):

```
## YYYY-MM-DD | conformance → <owner> — Non-conformant spec: <path>

[conformance] `<path>` is missing required field(s): <field list>.
These fields are required by the `<capability>` capability. Please add them.

→ <owner>

---
```

**Invocation log entry format** (per suite spec):

```
YYYY-MM-DD HH:MM UTC | conformance | files_read: N | catalogue_assisted: true/false | outcome: success/fail
```

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Active capability source | Where to read the list of active capabilities and governed scopes | *(required)* |
| Required fields per spec type | Per-capability field requirements | Owner, Status, Purpose, Related |
| Scope→feedback-inbox routing | Table mapping spec path patterns to feedback file targets | *(required)* |
| Dedup window | Days before re-nudging the same spec | 14 days |
| Nudge entry format | Override the default nudge entry template | Default format above |

## Rationale

Conformance nudges written into the feedback inbox the owner already reads require no new process — the owner's existing catchup or inbox-check habit surfaces them. The 14-day dedup window balances persistence (gaps are re-surfaced if not resolved) against noise (owners are not re-nudged daily for the same gap).

## Related

- [`../spec.md`](../spec.md) — suite spec; shared contracts (scheduling, retry, observability)
- [`../../catalogue/spec.md`](../../catalogue/spec.md) — catalogue capability; runs after this agent and captures same-day fixes; this agent reads its `specs.yaml` fast-path
- [`../implementations/README.md`](../implementations/README.md) — runtime contract
