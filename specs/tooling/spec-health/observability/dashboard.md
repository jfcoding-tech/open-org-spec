# Spec-Health: Observability Dashboard

**Owner:** Javier Fernandez
**Status:** Active
**Type:** Command — on-demand companion to the observability agent

Part of the [spec-health suite](../spec.md). Reads the suite's invocation log, failure log, catalogue, and weekly report at any time and renders the current state as a formatted terminal summary. Read-only — does not commit.

**Related:**
- [`spec.md`](spec.md) — the scheduled observability agent (writes the weekly report this dashboard reads)
- [`../spec.md`](../spec.md) — suite spec; shared contracts

## Extension points

This command reads adopter-declared paths. Each adopter declares the following values in their wiring layer; the steps below reference them by name.

| Extension point | Description |
|---|---|
| Invocation log path | File all agents write to on each run |
| Failure log path | File all agents write to on max-retry exhaustion |
| Report file path | Where the observability agent appends weekly sections |
| Catalogue path | The spec catalogue file |
| Feedback inbox paths | The set of `feedback.md` files conformance and decision-nudge write to |
| Conformant scopes | Scopes with proper scope-level governance in place |
| Non-conformant scopes | Known scopes without scope-level governance yet (completeness % is suppressed for these) |
| Pre-catalogue baseline | Assumed files per invocation before the catalogue existed (default 45) |
| Tokens-per-file estimate | Token proxy per file read (default 500) |

---

## Step 1 — Check for data

Read the adopter-declared invocation log. If the file contains no lines matching the entry format (lines starting with `- YYYY` pattern or any `|`-delimited entry), print:

```
No data yet — the invocation log is empty. Baseline accumulates as commands are used.
```

Then skip to Step 5 (conformance gaps from catalogue) and Step 6 (recent failures), since both can be populated even with an empty invocation log. Skip Step 2, 3, and 4.

If fewer than 3 days of entries exist (the earliest and latest log-entry dates span fewer than 3 days), append a note after rendering:

```
Note: fewer than 3 days of data — baseline is still accumulating. Figures will stabilise after more runs.
```

---

## Step 2 — Agent health (last 7 days)

Parse the adopter-declared invocation log line by line. Keep only entries where the date portion of the `YYYY-MM-DD HH:MM UTC` prefix falls within the last 7 days (compare to today's date minus 7 days; both inclusive). Discard header lines and blank lines.

For each entry, extract:
- Agent/command name (second pipe-delimited field)
- `files_read` value (integer after `files_read: `)
- `catalogue_assisted` value (`true` or `false`)
- `outcome` value (`success` or `fail`)

Group entries by agent/command name. For each group compute:
- Total runs
- Success count (entries where `outcome: success`)
- Failed count (entries where `outcome: fail`)
- Average `files_read` (arithmetic mean, rounded to nearest integer)
- `catalogue_assisted` percentage (entries with `catalogue_assisted: true` as a percentage of total, rounded to nearest integer)

Render:

```
## Agent health — last 7 days

| Agent              | Runs | Success | Failed | Avg files_read | Catalogue-assisted |
|--------------------|------|---------|--------|----------------|-------------------|
| /example           |  N   |    N    |   N    |      N         |       N%          |
...

Failures this period: N
```

If no entries fall in the last 7 days, print: `No runs recorded in the last 7 days.`

---

## Step 2a — Conformance agent output (last 7 days)

Walk the adopter-declared feedback inbox paths.

For each file, collect entries whose heading matches `## YYYY-MM-DD | conformance-agent` and whose date falls within the last 7 days (today minus 7 days, both inclusive).

Also collect entries whose date falls within the last 14 days (today minus 14 days) — used only for the chronic-spec calculation.

Compute:
- Total nudges written in the last 7 days (count of matching entries across all files)
- Nudges by scope (file path → count; only list scopes with at least 1 nudge)
- Chronic specs: any spec path mentioned in more than one nudge entry across the last 14 days

Render:

```
## Conformance agent — last 7 days

Nudges written: N
  - <scope-a>: N
  - <scope-b>: N
  - projects/<name>: N
  (only list scopes with at least 1 nudge)

Chronic non-conformance (nudged >1× in 14 days):
  - path/to/spec.md (N nudges)
  (or: None detected)
```

If no nudge entries found in the last 7 days, print: `No conformance nudges written in the last 7 days.`

---

## Step 2b — Catalogue health

Read the adopter-declared catalogue. Check the `generated:` field at the top of the file. If more than 25 hours have elapsed since the `generated:` timestamp, or the file does not exist, skip this section and note:

```
Catalogue health: stale or absent — will be covered in Step 5.
```

If the catalogue is fresh, compute:
- Total spec entries (count of items under `specs:`)
- Total decision entries (count of items under `decisions:`)
- Total feedback inbox entries (count of items under `feedback_inboxes:`)
- Completeness: specs with non-empty `owner` AND non-empty `status` as a percentage of total specs (rounded to nearest integer)
- Open feedback entries: sum of `open_entries` across all `feedback_inboxes` entries
- Decisions by status: group `decisions` entries by `status` field, count per value (only list statuses with at least 1 entry)

Render:

```
## Catalogue health

Last generated: YYYY-MM-DD
Entries: N specs · N decisions · N feedback inboxes

Spec completeness: N% (N of N have owner + status)
Open feedback entries: N (across N inboxes)

Decision status breakdown:
  - accepted: N
  - proposed: N
  - deferred: N
  (only list statuses with at least 1 entry)
```

If the catalogue is fresh, also compute a **per-scope completeness breakdown**.

**Conformant scopes** are those that have proper scope-level governance in place — the adopter-declared conformant scopes list, plus any scope explicitly listed as governed in the adopter's active capabilities. All other scopes found in the catalogue are non-conformant.

**Non-conformant scopes** are the adopter-declared non-conformant scopes list — scopes known to lack scope-level governance. The adopter maintains this list, removing scopes once they are properly constituted.

Group all `specs` entries by their `scope` field. Split the scopes into two groups: conformant (per the adopter list) and non-conformant (per the adopter list).

For each **conformant** scope, compute:
- Total specs in that scope
- Specs with non-empty `owner` field
- Specs with non-empty `status` field
- Completeness % = specs where BOTH owner AND status are non-empty, divided by total specs in scope (rounded to nearest integer)

Only include scopes with at least 2 specs (single-spec scopes are noise at this level of analysis).

Sort ascending by completeness % (lowest first — scopes needing most attention at the top).

Apply these RAG thresholds:
- 🔴 below 70% — needs attention
- 🟡 70–89% — acceptable, room to improve
- 🟢 90% and above — healthy

For each **non-conformant** scope, record only the total spec count — do not compute or display a completeness %. Showing a % would imply the scope is properly constituted when it is not.

Render after the decision status breakdown:

```
Per-scope completeness — conformant scopes (owner + status both present):

  🔴 <scope-a>                       52%  (12 of 23 specs complete)
  🟢 <scope-b>                       88%  (15 of 17 specs complete)
  🟢 <scope-c>                       94%  (17 of 18 specs complete)
  🟢 <scope-d>                      100%   (6 of 6 specs complete)
  ...

  RAG key: 🔴 < 70%   🟡 70–89%   🟢 90%+

Non-conformant scopes (completeness % not shown — scope-level governance pending):

  - <non-conformant-scope>  (N specs in catalogue)
    Pending: <reason — see adopter governance>
```

(The numbers above are illustrative — compute from live catalogue data.)

If all qualifying conformant scopes are 90%+, print: `All conformant scopes at 90%+ completeness.` instead of the conformant table (still render the non-conformant group if any exist).

If the catalogue is absent or stale (already handled at the top of Step 2b), skip this subsection entirely — it is already covered by the stale-catalogue note.

---

## Step 2c — Decision-nudge output (last 14 days)

Using the same feedback inbox paths as Step 2a, collect entries whose heading matches `## YYYY-MM-DD | decision-review-nudge` and whose date falls within the last 14 days (today minus 14 days, both inclusive).

Compute:
- Total nudges written
- Nudges by scope (file path → count; only list scopes with at least 1 nudge)
- Chronic decisions: any decision path mentioned in more than one nudge entry (stale and repeatedly nudged — suggests a blocked decision). Include the owner if extractable from the nudge entry body.

Render:

```
## Decision-nudge — last 14 days

Nudges written: N
  - decisions/ (repo-wide): N
  - clusters/<name>/decisions/: N
  - projects/<name>/decisions/: N
  (only list scopes with at least 1 nudge)

Chronic stale decisions (nudged >1× in 14 days):
  - path/to/decision.md (N nudges) — <owner if extractable>
  (or: None detected)
```

If no nudge entries found, print: `No decision nudges written in the last 14 days.`

---

## Step 3 — Catalogue efficiency

Using the entries filtered in Step 2:

- Compute the average `files_read` across all entries where `catalogue_assisted: true` (call this the **catalogue-assisted avg**).
- Compute the average `files_read` across all entries where `catalogue_assisted: false` (call this the **non-assisted avg**).
- Pre-catalogue baseline is the adopter-declared baseline (default **45 files/invocation**, assumed; will be replaced with a measured figure once four weeks of data are available).
- Count of catalogue-assisted invocations in the period.
- Estimated token saving = `(baseline − catalogue-assisted avg) × catalogue-assisted invocation count × tokens-per-file estimate`. Only compute if there is at least one catalogue-assisted run; otherwise render `—`.

Render:

```
## Catalogue efficiency

Pre-catalogue baseline (assumed): 45 files/invocation
Current avg (catalogue-assisted runs): N files/invocation   [or: — (no catalogue-assisted runs yet)]
Current avg (non-assisted runs): N files/invocation          [or: — (no non-assisted runs yet)]
Estimated saving this week: ~X,000 tokens                    [or: — (no catalogue-assisted runs yet)]
```

If the catalogue-assisted avg is higher than the baseline, note: `Catalogue-assisted runs are reading more files than the baseline — investigate whether the catalogue is being used or bypassed.`

---

## Step 4 — Last weekly report summary

Read the adopter-declared report file. Find the last section that begins with `## Week of `. Extract everything from that heading to either the next `## ` heading or end of file.

Render:

```
## Last weekly report

[content of the most recent ## Week of YYYY-MM-DD section, rendered as-is]
```

If no `## Week of` section exists, print: `No weekly report yet — the observability agent has not run.`

---

## Step 5 — Conformance gaps (from catalogue)

Read the adopter-declared catalogue. Check the `generated:` field at the top of the file. Compare to today's date and time; if more than 25 hours have elapsed since the `generated:` timestamp, print:

```
## Conformance gaps

Catalogue is stale or absent — run the catalogue agent to regenerate.
```

If the file does not exist, print the same message.

If the catalogue is fresh, scan all entries. Count:
- Specs where `owner` is an empty string (`owner: ""` or `owner:` with no value)
- Specs where `status` is an empty string (`status: ""` or `status:` with no value)
- Decision records where `owner` is an empty string

Render:

```
## Conformance gaps

Open gaps in the catalogue:
  - Specs missing owner: N
  - Specs missing status: N
  - Decisions missing owner: N

(Source: adopter catalogue — generated YYYY-MM-DD)
```

If all counts are zero, print: `No conformance gaps detected in the current catalogue snapshot.`

---

## Step 6 — Recent failures

Read the adopter-declared failure log. Keep only entries where the date portion falls within the last 14 days (compare to today minus 14 days; both inclusive).

Render:

```
## Recent failures

[entries from the last 14 days, one per line, as-is from the file]
```

If no entries match, print: `No failures recorded in the last 14 days.`

---

## Model guidance

**Suggested model:** a fast, low-cost model — reading and formatting existing metrics, no reasoning required.
**Announce to user:** At the start of this command, output one line noting the model in use and that it is reading and formatting existing metrics, no reasoning step needed.
