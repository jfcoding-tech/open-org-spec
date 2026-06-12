---
description: Generate spec-touch — a per-scope lived-in ratio report from git edit history of spec files
owner: Javier Fernandez
canonical_spec: open-org-spec/specs/observability/spec-activity/spec.md
canonical_spec_version: "{{canonical_spec_version}}"
execution_context: claude-code
---

# /spec-activity

Generates **spec-touch** — a per-scope view of how lived-in the spec surface is. For every tracked `.md` spec file under the configured scope paths, this command reads the last commit date from git, classifies each spec as fresh or stale against a recency threshold, and computes a **lived-in ratio** per scope (specs edited recently ÷ total specs). The diagnostic for surface-area adoption: it distinguishes a repo whose specs are actively maintained from one that accumulates write-once artefacts.

All logic in this command is **inline and self-contained**. It does **not** read any file under `.open-org-spec/extensions/` or `open-org-spec/specs/` at runtime. The extension points below are install-time variables, substituted by `/adhere-to tooling` from the adopter's manifest extension.

Default variable values (substituted at install time):

| Variable | Default |
|---|---|
| `{{scope_paths}}` | `clusters/ functions/ ai-factory/ cloudops/ decision-intelligence/ projects/` |
| `{{stale_threshold_days}}` | `90` |
| `{{model}}` | `claude-sonnet-4-6` |
| `{{output_path}}` | `governance/observability/spec-touch.md` |

The scope paths are the structural roots walked for spec files. The following sub-paths are **always excluded** regardless of scope: `projects/closed/`, any `context/` directory, and any `_template/` directory.

---

## Execution logic

### Step 0 — Pre-flight

1. Confirm the working directory is a git repository: `git rev-parse --is-inside-work-tree`. If not, abort with a clear error — this command depends on git history.
2. Record today's date (`date +%F`) for the generation header and the staleness comparison.

### Step 1 — Enumerate spec files per scope

For each scope root in `{{scope_paths}}`, find every tracked markdown file, excluding the always-excluded sub-paths. Use git's tracked-file list so untracked scratch files are ignored:

```bash
git ls-files '<scope_root>/*.md' \
  | grep -v -E '(^|/)(projects/closed|context|_template)(/|$)'
```

Run this once per scope root and keep the file list grouped **by its scope root** (the first path segment — e.g. `clusters`, `functions`, `ai-factory`, `cloudops`, `decision-intelligence`, `projects`). A file's scope is determined by which scope root it lives under.

If a scope root does not exist in the repo, skip it silently — adopters may not have every structural folder.

### Step 2 — Last edit date per file

For each file collected in Step 1, get the date of its most recent commit:

```bash
git log -1 --format=%as -- <path>
```

`%as` yields the author date as `YYYY-MM-DD`. If the command returns empty (file staged but never committed), treat the file as **fresh** (edited today) — it is brand new, not stale.

### Step 3 — Classify fresh vs stale

Compute the cutoff date: today minus `{{stale_threshold_days}}` days.

- macOS: `date -v-{{stale_threshold_days}}d +%F`
- Linux: `date -d '-{{stale_threshold_days}} days' +%F`

Detect OS with `uname -s` first, then use the matching form.

For each file, compare its last-edit date (Step 2) to the cutoff:

- **Fresh** — last edit date is on or after the cutoff (edited within the window).
- **Stale** — last edit date is before the cutoff (not edited in > `{{stale_threshold_days}}` days).

### Step 4 — Compute lived-in ratio per scope

For each scope root:

- `total` = number of spec files found in Step 1 for that scope.
- `fresh` = number classified fresh in Step 3.
- **lived-in ratio** = `fresh / total`, rendered as a percentage to one decimal place. If `total` is 0, render the ratio as `—` (no specs, no ratio).

Also compute repo-wide totals: sum of `total` and sum of `fresh` across all scopes, and the repo-wide lived-in ratio.

### Step 5 — Write the output file

Write the report to `{{output_path}}`. The file must begin with a machine-readable YAML front-matter block carrying the key metrics, followed by the prose body.

Front-matter (exact keys):

```yaml
---
generated: <YYYY-MM-DD>
key_metrics:
  total_specs: <N>
  fresh_specs: <N>
  stale_specs: <N>
  lived_in_ratio_pct: <N.N>
  stale_threshold_days: {{stale_threshold_days}}
---
```

Body sections, in order:

1. **Generation header** — `Generated: <YYYY-MM-DD>`, the recency window (`{{stale_threshold_days}}` days), and the scope roots walked.

2. **Summary stats** — repo-wide total specs, fresh count, stale count, and repo-wide lived-in ratio. Name the scope with the highest lived-in ratio and the one with the lowest.

3. **Per-scope lived-in ratio table** — one row per scope root, sorted by descending lived-in ratio:

   | Scope | Total specs | Fresh (≤ {{stale_threshold_days}}d) | Stale | Lived-in ratio |
   |---|---|---|---|---|
   | clusters | … | … | … | …% |

4. **Stale specs** — every spec classified stale in Step 3, sorted by last-edit date ascending (oldest first). Columns: spec path, last edit date, days since last edit. This is the re-validation queue. If the list exceeds 30 entries, show the oldest 30 and note the total count.

If `{{output_path}}`'s parent directory does not exist, create it before writing.

### Step 6 — Log the invocation

Detect OS, then call the pre-approved log script if present:

1. `uname -s` to detect OS (pre-approved, no prompt).
2. macOS / Linux: `bash governance/observability/command-log.sh /spec-activity <files_walked_count> true <outcome> {{model}} || true`
3. Windows: `powershell -File governance/observability/command-log.ps1 /spec-activity <files_walked_count> true <outcome> {{model}}; $true`

Where `<outcome>` is `success` if the output file was written, or `error` if it could not be written. If neither log script exists, skip silently.

---

## Output

Return the following digest after the file is written:

```
/spec-activity complete.
Output: {{output_path}}
Generated: <YYYY-MM-DD>

  Total specs:      <N>
  Fresh (≤<stale_threshold_days>d): <N>
  Stale:            <N>
  Lived-in ratio:   <N.N>%
  Highest scope:    <scope> (<N.N>%)
  Lowest scope:     <scope> (<N.N>%)
```
