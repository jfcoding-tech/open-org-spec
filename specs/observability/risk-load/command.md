---
description: Regenerate the risk-load index — open risks by scope and owner, RAG distribution, awaiting-disposition queue
owner: open-org-spec (observability capability — risk-load tool)
canonical_spec: open-org-spec/specs/observability/risk-load/spec.md
canonical_spec_version: "{{canonical_spec_version}}"
execution_context: automated
---

# /risk-load

Busuu wiring: [`.open-org-spec/extensions/observability/spec.md`](../../../../.open-org-spec/extensions/observability/spec.md)

This command is owned by the observability capability (Javier Fernandez). Spawn a subagent to execute it — this keeps the main session context clean:

Spawn an Agent (`model: "{{model}}"`) with this instruction: "Execute the risk-load logic below and return ONLY the formatted output to the parent agent — no intermediate steps, no tool call descriptions, no file paths."

Display the returned output to the user.

Output is written to [`{{output_path}}`](../../../../{{output_path}}) and a short digest is returned to the caller.

---

## Delta mode (automated invocation)

When invoked from a CI workflow (environment variable `CI=true` or `GITHUB_ACTIONS=true`), the command runs in **delta mode**:

- Read the existing `{{output_path}}` and record its generation timestamp.
- If the file is less than 23 hours old, skip the full execution and return the cached digest with a note: *"Skipped — cached output from <timestamp> is still fresh."*
- If the file is absent or older than 23 hours, proceed with the full execution logic below.

Delta mode avoids redundant re-scans when multiple workflows overlap within the same day.

---

## Execution logic

### Step 1 — Read the risk registry

Read `governance/catalogue/risks.yaml`. Parse every entry in the `risks:` list.

For each entry, extract:

- `id` — the `R-NNN` identifier
- `title` — short label
- `status` — `open | deferred | mitigated | accepted | closed`
- `rag` — the cached RAG value from the registry (`RED | AMBER | GREEN`)
- `owner` — list of named person(s); may be empty or absent
- `scope` — the `<type>/<slug>` scope reference (or `programme` for cross-cutting risks)
- `escalation_threshold` — integer days
- `disposition_at` — ISO date of last disposition action; may be empty or absent
- `created_at` — ISO date from the registry entry or inferred from the `path` filename

**If `governance/catalogue/risks.yaml` is absent or empty:** write `{{output_path}}` with a header and a single note — *"Risk registry not yet generated — run /risk-registry to populate."* Return the digest with all counts as `0`. Do not abort.

**RAG recomputation (required even when reading from registry):** Do not trust the cached `rag` value without verification. For every entry with `status: open`, recompute `rag` from:

- `age_days` = today − `created_at` (ISO date arithmetic; use the filename date from `path` if `created_at` is absent)
- `escalation_threshold` (integer days from the entry)
- Derivation:
  - **GREEN** — `age_days < 0.5 × escalation_threshold`
  - **AMBER** — `0.5 × escalation_threshold ≤ age_days < escalation_threshold`
  - **RED** — `age_days ≥ escalation_threshold`
- For entries with `status` other than `open` (`deferred`, `mitigated`, `accepted`, `closed`): force `rag` to `GREEN` regardless of age.

If the recomputed value differs from the cached registry value, use the recomputed value and note the discrepancy in the output (but do not modify the registry file — that is the risk-registry agent's job).

### Step 2 — Read the scope registry

Read `governance/catalogue/scopes.yaml`. Build a lookup table: `scope field value → { lead, feedback_inbox, type }`.

Map:

- A risk with `scope: cluster/product-development` → look up slug `product-development` in scopes of type `cluster`
- A risk with `scope: programme` → display as "Programme (cross-cutting)"
- A risk whose `scope` field is absent → display as "Unscoped"
- A risk whose `scope` value is not found in the catalogue → display verbatim with a `[scope-unresolved]` warning

If `governance/catalogue/scopes.yaml` is absent, skip scope-name resolution and use the raw `scope` field values as labels.

### Step 3 — Compute summary statistics

From the full risk list (all statuses):

- **Total open** — count of entries with `status: open`
- **RED** — count of open entries with recomputed `rag: RED`
- **AMBER** — count of open entries with recomputed `rag: AMBER`
- **GREEN** — count of open entries with recomputed `rag: GREEN`
- **Unowned** — count of open entries where `owner` is empty, absent, or `[]`
- **Awaiting disposition** — count of open entries where `escalation_threshold` has been breached (i.e. `age_days ≥ escalation_threshold`) AND `disposition_at` is empty or absent (i.e. no disposition has ever been recorded)

Flag **unowned** as critical — an acknowledged risk with no owner is ungoverned.

### Step 4 — Build the by-scope view

Group **open** risks by their `scope` field (use the resolved scope label from Step 2).

For each scope group, compute:

- RED count
- AMBER count
- GREEN count
- Total open count

Sort groups by RED count descending (highest RED first), then by total open count descending as a tiebreaker.

Include a row for `programme` (cross-cutting) risks if any exist.
Include a row for `Unscoped` if any risks have no `scope` field.

### Step 5 — Build the by-owner view

Group **open** risks by their `owner` field. When a risk has multiple owners, count it under each owner separately.

For each owner, compute:

- Total open risks assigned
- RED count

Sort by RED count descending, then total descending as a tiebreaker.

Surface **"Unowned"** as a special row at the top if any open risks have no declared owner. This row is flagged as critical.

### Step 6 — Build the awaiting-disposition list

Collect all open risks where `age_days ≥ escalation_threshold` AND `disposition_at` is empty or absent.

For each such risk, record:

- `id`
- `title`
- Resolved scope label (from Step 2)
- Owner(s)
- `age_days`
- `escalation_threshold`
- Days overdue = `age_days − escalation_threshold`

Sort by days overdue descending (most overdue first).

### Step 7 — Render and write the output file

Write `{{output_path}}` with the following structure:

```
# Risk-load

*Generated by /risk-load on YYYY-MM-DD HH:MM. Repo HEAD: <short-sha>. Re-run the command to refresh.*

## Summary

- **Total open risks:** N
- **RED:** N ← risks at or past their escalation threshold
- **AMBER:** N ← risks approaching their escalation threshold (50–100%)
- **GREEN:** N ← risks within threshold
- **Unowned:** N [CRITICAL — no accountable owner declared]
- **Awaiting disposition:** N ← open, past threshold, no disposition on record

## By scope

*(sorted by RED count descending)*

| Scope | Lead | RED | AMBER | GREEN | Total open |
|---|---|---|---|---|---|
| <scope label> | <lead from catalogue or —> | N | N | N | N |

## By owner

*(sorted by RED count descending; Unowned row first if any)*

| Owner | RED | Total open |
|---|---|---|
| **Unowned** [CRITICAL] | N | N |
| <owner name> | N | N |

## Awaiting disposition

*(open risks past escalation threshold with no disposition recorded — sorted by days overdue)*

| ID | Title | Scope | Owner(s) | Age (days) | Threshold | Days overdue |
|---|---|---|---|---|---|---|
| <id> | <title> | <scope> | <owner(s)> | N | N | N |
```

**If the awaiting-disposition list is empty:** render the section with a single line — *"None — all open risks have a disposition on record or are within threshold."*

**If unowned risks exist:** add a callout block immediately after the Summary section:

```
> **Critical: N unowned open risks.** These risks have no declared owner — no one is accountable for dispositioning them. Route to the governance owner for immediate assignment.
```

**Generation header format:** single line — `*Generated by /risk-load on YYYY-MM-DD HH:MM. Repo HEAD: <short-sha>. Re-run the command to refresh.*`

Obtain `<short-sha>` by running `git rev-parse --short HEAD`.

**Scope label resolution:** use the human-readable scope name from the catalogue when available; fall back to the raw `scope` field value. `programme` displays as `Programme (cross-cutting)`.

### Step 8 — Commit and push

After writing `{{output_path}}`:

1. Stage the file: `git add {{output_path}}`
2. Commit: `git commit -m "chore: risk-load update — YYYY-MM-DD"`
3. Attempt push. On failure, apply the retry contract below.

**Retry contract:**

1. Before any write, verify the repo is in a state safe to write to.
2. On push failure:
   - Run `git checkout -- .` to discard any local changes that conflict.
   - Run `git pull --rebase`.
   - Re-stage and re-commit the output file.
   - Retry the push. Increment the retry counter: attempt N of 3.
3. Maximum attempts: **3**. Count starts at 1 on the initial run.
4. On exhaustion (N > 3), append to `governance/observability/spec-health/agent-failures.md`:
   ```
   YYYY-MM-DD HH:MM UTC | risk-load | attempt <N> failed: <reason>
   ```
   Return the digest with `Output: PARTIAL — push failed after 3 attempts`.

### Step 9 — Log invocation

At the end of this command, detect OS then call the pre-approved log script:

1. Run `uname -s` to detect OS (pre-approved, no prompt).
2. macOS / Linux (uname succeeded): `bash governance/observability/command-log.sh /risk-load <files_read> true <outcome> {{model}} {{canonical_spec_version}} || true`
3. Windows (uname failed): `powershell -File governance/observability/command-log.ps1 /risk-load <files_read> true <outcome> {{model}} {{canonical_spec_version}}; $true`

Arguments:
- `files_read` — count of distinct files the subagent opened (pass `0` if unknown)
- `catalogue_assisted` — `true`; this agent reads `governance/catalogue/risks.yaml` and `governance/catalogue/scopes.yaml`
- `outcome` — `success`, `partial` (push failed), or `fail` (output file not written)

If neither log script exists, skip silently.

---

## Return digest

After writing the file, return this digest to the caller:

```
Risk-load index regenerated → {{output_path}}

- N open risks: N RED, N AMBER, N GREEN.
- Unowned: N [CRITICAL — no owner declared]
- Awaiting disposition: N risks past threshold with no disposition on record.
- Highest-risk scope: <scope label> (N RED).
- Highest-load owner: <owner name> (N open, N RED).
```

If the risk registry was absent: return `Risk registry not found — run /risk-registry first.`

---

## Model guidance

**Suggested model:** {{model}} — risk record aggregation and table rendering — no reasoning required.
**Announce to user:** At the start of this command, output one line: *"Running on {{model}} — risk aggregation across catalogue, no reasoning step needed."*
