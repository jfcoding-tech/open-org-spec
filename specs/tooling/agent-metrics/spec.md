# Agent-metrics

**Owner:** Javier Fernandez
**Status:** Active

A standalone tooling capability. Agent-metrics measures the performance of **all** automated agents and commands in the repo — not just the spec-health suite. It reads the adopter-declared invocation log shared by every agent and command, computes per-agent metrics and a relative cost index, detects optimisation opportunities, and writes a weekly report.

## Purpose

Automated agents and instrumented commands are infrastructure. Infrastructure that cannot be measured cannot be justified or improved. Agent-metrics provides the evidence base for deciding whether to expand, maintain, or retire any agent or command — by tracking file-read counts as a proxy for token cost, surfacing failure and success rates, and computing a relative cost index across every agent and command that logs to the shared invocation log.

Its scope is repo-wide: any agent or command that appends to the adopter-declared invocation log is measured. It is not limited to the spec-health suite — the conformance agent, the catalogue agent, decision-escalation, observability tools, catchup, and every instrumented command all appear in its report.

## Inputs

- Invocation log path (extension point — the file all agents and commands write to on each run)
- Failure log path (extension point — the file all agents write to on max-retry exhaustion)
- Report file path (extension point — where the weekly sections are appended)
- Catalogue path (extension point — read to count specs with missing fields)
- Pre-catalogue baseline (extension point — assumed average files per invocation before the catalogue existed; default 45)
- Tokens-per-file estimate (extension point — token proxy per file read; default 500)
- Contributor roster sources (extension point — adopter-declared files listing known contributors; see Step 8)
- Contributor usage output path (extension point — where the contributor-usage table is written; see Step 8)
- Optimisation suggestions path (extension point — where optimisation suggestions are written; see Step 10)
- Tier 1 commands (extension point — adopter-declared commands expected to use subagents; see Step 10 Rule 2)

## Pattern

### Step 1 — Read invocation log

Read all entries in the adopter-declared invocation log for the last 7 days (entries where the date field falls within the current week window). Group by agent/command name. Every agent and command that logs to this file is in scope — there is no filter by suite.

### Step 2 — Compute per-agent metrics

For each agent or command:

- Invocation count
- Average `files_read`
- Success count and failure count (from `outcome:` field) — the success rate is the fraction of `outcome: success` entries
- `catalogue_assisted` ratio (entries with `catalogue_assisted: true` as a fraction of total)

### Step 3 — Read failure log

Read the adopter-declared failure log. Count entries per agent for the last 7 days.

### Step 4 — Read catalogue for open gaps

Read the adopter-declared catalogue. Count specs where `owner` is empty string and specs where `status` is empty string. These are open conformance gaps as of the most recent catalogue snapshot.

### Step 5 — Compute estimated token saving

Token saving estimate for the week:

```
saving = (pre-catalogue baseline − avg files_read across catalogue-assisted runs)
         × catalogue-assisted invocation count
         × tokens-per-file estimate
```

Note in the report whether the baseline figure is assumed (pre-measured) or derived from measured data.

### Step 6 — Append weekly report section

Append to the adopter-declared report file (append only — never overwrite):

```markdown
## Week of YYYY-MM-DD

- Catalogue-assisted invocations: N
- Avg files read (catalogue-assisted): X
- Avg files read (pre-catalogue baseline): <baseline value>
- Estimated token saving this week: ~X,000 tokens
- Agent failure rate: N%
- Open conformance gaps (from catalogue): N specs missing owner/status
```

If fewer than 3 data points are available for the week, write the available data and note the low sample size.

### Step 7 — Log invocation

Append one entry to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | agent-metrics | files_read: N | catalogue_assisted: true | outcome: success/fail
```

### Step 8 — Contributor usage analysis

Build a population-level picture of who is using the tooling in this repo.

a. **Collect known contributors.** Read the adopter-declared contributor roster sources and extract all named contributors. Each adopter declares one or more files that list contributors (team rosters, contributor-mode files, per-scope people files). Deduplicate by full name (case-insensitive). This is the "known roster."

b. **Parse the invocation log for the period.** For each entry in the last 7 days:
   - `session_start | contributor: X` → record a session for X
   - `/<command> | contributor: X` → record a command run for X (if contributor field present)
   - Entries without a contributor field → attribute to "unknown" bucket, do not include in the roster cross-reference

c. **Classify each roster member:**
   - **Active** — has ≥1 command entry in the period
   - **Session only** — has ≥1 session_start entry but 0 command entries
   - **No activity** — no entries of any kind in the period

d. **Write the contributor-usage output file** (adopter-declared path).
   Overwrite the file with the three-tier table populated from the classification above.
   Format per the existing file structure (Active / Session only / No activity tables).
   Set "Last generated" to today's date.
   Set "Period" to the 7-day window used.

e. **Include in the weekly report.** Append a summary line to the weekly section:
   `Contributor usage: N active / N session-only / N no-activity (see contributor-usage file)`

### Step 9 — Relative cost index

For each command/agent in the last 7 days, compute a relative cost proxy:

```
cost_index = model_factor × avg_files_read × invocation_count
```

Model factors: `haiku = 0.267`, `sonnet = 1.0`, `opus = 3.75`. If model field is absent from log entries, assume `sonnet = 1.0`.

Rank commands by total weekly cost proxy. Express as a dimensionless index relative to the baseline (one Sonnet run reading 10 files = index 10.0).

**Never express as dollars.** Always label: *"Relative cost proxy — not actual spend. Index 1.0 = one Sonnet run reading one file."*

Append to the weekly report section:

```
Cost index (this week):
  /<command-a>    index: X.X  (N runs × avg files Y, model sonnet)
  /<command-b>    index: X.X  (N runs × avg files Y, model haiku)
  [rank highest to lowest total weekly cost]
  Note: relative proxy only — not actual spend.
```

### Step 10 — Optimisation opportunity detection (three rules, high confidence only)

**Bootstrapping gate:** Count the number of distinct calendar days represented in the invocation log. If fewer than 14 days: write to the suggestions file: `"Bootstrapping — N days of data accumulated. Optimisation detection begins YYYY-MM-DD (14 days from first entry). No suggestions this week."` — then STOP step 10. Do not generate any suggestions.

If 14+ days of data exist, apply exactly these three rules. No other rules.

**Rule 1 — Catalogue fast-path available**
Trigger: any command with `avg_files_read > 10` AND `catalogue_assisted_ratio < 20%` across the last 7 days.
Action: generate suggestion — catalogue fast-path could reduce file reads.
Confidence: HIGH.

**Rule 2 — Context isolation not applied**
Trigger: any command in the adopter-declared Tier 1 command list that shows `subagents: 0` (or subagents field absent) across ALL runs this week, **and** whose command file does not declare `execution_context: automated`. Commands with `execution_context: automated` are excluded — they run in CI environments where subagents are not spawned by design, not by omission.
Action: generate suggestion — subagent execution not detected; confirm context isolation is applied.
Confidence: HIGH.

**Rule 3 — Recurring high file-read gap**
Trigger: same command appears in BOTH this week AND last week with `avg_files_read > 15` AND `catalogue_assisted: false` both weeks.
Action: generate suggestion as "Recurring — same gap two weeks running", elevated priority.
Confidence: VERY HIGH.

For each triggered rule, generate one entry in the adopter-declared optimisation suggestions file using the format defined in that file. Mark each as `Status: ⏳ Pending review`.

**Staleness re-check:** For any suggestions already in the file marked `Status: ⏳ Pending review`, re-run the triggering rule. If the issue is resolved this week (rule no longer triggers), update the suggestion status to `Status: ✅ Auto-resolved YYYY-MM-DD — issue no longer detected`. If the suggestion has been pending for more than 21 days, change status to `Status: ⚠️ Stale — needs decision (pending >21 days)`.

### Step 11 — Append optimisation summary to weekly report

After writing suggestions, append one line to the weekly report section:

```
Optimisation suggestions: N new | N resolved | N stale | N pending review — see optimisation suggestions file
```

If bootstrapping: `Optimisation detection: bootstrapping (N/14 days). Starts YYYY-MM-DD.`

## Data contracts

**Weekly report section format** (appended to the report file):

The file must begin with a machine-readable YAML front-matter block:

```yaml
---
generated: YYYY-MM-DDTHH:MM:00Z
tool: agent-metrics
period_days: 7
key_metrics:
  catalogue_assisted_invocations: N
  estimated_token_saving_tokens: N
  agent_failure_rate_pct: N.N
  open_conformance_gaps: N
  active_contributors: N
  engagement_rate_pct: N.N
---
```

Followed by the weekly section body:

```markdown
## Week of YYYY-MM-DD

- Catalogue-assisted invocations: N
- Avg files read (catalogue-assisted): X
- Avg files read (pre-catalogue baseline): <baseline value>
- Estimated token saving this week: ~X,000 tokens
- Agent failure rate: N%
- Open conformance gaps (from catalogue): N specs missing owner/status
```

**Contributor-usage output format** (written to the adopter-declared contributor usage output path):

The file must begin with a machine-readable YAML front-matter block:

```yaml
---
generated: YYYY-MM-DDTHH:MM:00Z
tool: agent-metrics/contributor-usage
period_days: 7
key_metrics:
  claude_active_users: N
  claude_session_only_users: N
  claude_inactive_users: N
  engagement_rate_pct: N.N
---
```

Followed by the three-tier contributor table (Active / Session only / No activity) as described in Step 8d.

**Invocation log entry format:**

```
YYYY-MM-DD HH:MM UTC | agent-metrics | files_read: N | catalogue_assisted: true | outcome: success/fail
```

## Dashboard

An on-demand companion to the scheduled agent. The dashboard command (`/agent-metrics-dashboard`) reads the metrics files and the catalogue at any time and renders the current state as a formatted terminal summary. It does not write to the repo. The scheduled agent and the dashboard are complementary: the agent generates the weekly report; the dashboard surfaces the live picture between scheduled runs. See [`dashboard.md`](dashboard.md).

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Invocation log path | File all agents and commands write to on each run | *(required)* |
| Failure log path | File all agents write to on max-retry exhaustion | *(required)* |
| Report file path | Where weekly sections are appended | *(required)* |
| Catalogue path | Read to count open conformance gaps | *(required)* |
| Pre-catalogue baseline | Files per invocation before catalogue existed | 45 |
| Tokens-per-file estimate | Token proxy for one file read | 500 |
| Contributor roster sources | Files listing known contributors (Step 8) | *(required for Step 8)* |
| Contributor usage output path | Where the contributor-usage table is written (Step 8) | *(required for Step 8)* |
| Optimisation suggestions path | Where optimisation suggestions are written (Step 10) | *(required for Step 10)* |
| Tier 1 commands | Commands expected to use subagents (Step 10 Rule 2) | *(required for Rule 2)* |

## Rationale

A file-read count is the lowest-friction proxy for token cost available from the invocation log format. It does not require the tool to instrument the actual model calls — agents and commands log `files_read` as a single integer. The default 45-file pre-catalogue baseline is a deliberate assumption: commands that walked 30–80 files before the catalogue existed motivate the figure. The assumption is replaced with a measured figure once four weeks of invocation-log data are available.

Measuring all agents and commands from one shared log — rather than scoping the measurement to a single suite — means the relative cost index is comparable across the whole repo. A spec-health agent and a contributor-facing command sit in the same ranking, so the adopter can see where token cost actually concentrates.

## Related

- [`../spec.md`](../spec.md) — the tooling capability; delta mode and the universal invocation-log instrumentation requirement.
- [`../catalogue/spec.md`](../catalogue/spec.md) — produces the catalogue this tool reads for open-gap counts; one of the agents this tool measures.
- [`../spec-health/conformance/spec.md`](../spec-health/conformance/spec.md) — one of the agents this tool measures.
- [`../../governance-at-scope/tools/decision-escalation/spec.md`](../../governance-at-scope/tools/decision-escalation/spec.md) — one of the agents this tool measures.
- [`dashboard.md`](dashboard.md) — on-demand dashboard companion command.
- [`review-optimisations.md`](review-optimisations.md) — interactive review of the optimisation suggestions this tool generates.
