# Spec-activity

A tool of the open-org-spec observability capability. Aggregates per-spec edit history: how many distinct people have edited each spec over the rolling window, and how many edits in total. Distinguishes *lived-in* specs (multiple editors, recurring edits) from *write-once-and-forget* specs (one author, untouched). The diagnostic for surface-area adoption.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** an adopter wires a relay at their command directory (e.g. `.claude/commands/spec-activity.md`), with an extension at `.open-org-spec/extensions/observability/spec-activity/spec.md`.

## Purpose

A spec-driven repository can grow in volume without growing in adoption — specs get committed, then never revisited. Two questions distinguish a living spec from an artefact:

- **Has anyone other than the original author edited it?** Multi-editor specs are real collaboration surfaces; single-editor specs are individual documents that happen to live in git.
- **Has anyone edited it recently?** A spec untouched for months is either stable (fine — it describes something stable) or abandoned (a failure mode: it's outdated and no-one is updating it).

This tool produces a per-scope view of these two signals. The result is a map of where the surface is alive (clusters with high lived-in-ness) and where it is mausoleum (clusters with high spec count but low edit recency).

## Pattern

### Inputs

- **Git log per file** — `git log --follow --format='<commit-date>|<author-name>' -- <path>` for each tracked markdown file.
- **People resolution** — same canonicalisation as [`contributor-activity`](../contributor-activity/spec.md): contributor-modes file, then `people.md` rosters, then heuristic alias collapse.
- **Time windows** — declared by the adopter's extension. Defaults: 90 days for recency, lifetime for distinct-editor count.

### Step 1 — Walk specs

For each markdown file under the scope tree (excluding generated outputs in `governance/observability/`), collect:

- First commit date.
- Last commit date.
- Total commit count over lifetime.
- Distinct canonical authors over lifetime.
- Commits within the recency window (default 90 days).
- Distinct canonical authors within the recency window.

### Step 2 — Bucket

Each spec is classified into one of four buckets:

- **Lived-in** — 2+ distinct authors AND at least one edit within the recency window.
- **Stable** — 1 author, edit within recency window. Reasonable for description-of-stable-thing specs.
- **Untouched recent** — 0 edits within recency window, but recent enough overall to be active. Either stale or genuinely settled.
- **Abandoned** — 0 edits within recency window, first-commit > recency window ago. Either the spec is timeless (uncommon) or genuinely forgotten (more likely).

### Step 3 — Aggregate per scope

For each top-level scope folder:

- Total spec count.
- Bucket distribution.
- Most-edited spec in window.
- Specs with 0 author-other-than-creator (write-once flags).

### Step 4 — Render

Cached markdown file. The output file must begin with a machine-readable YAML front-matter block containing these key metrics, followed by the prose body.

```yaml
key_metrics:
  collective_ownership_pct: N.N
  abandoned_count: N
  total_specs: N
```

The file contains:

1. **Generation header.**
2. **Summary** — total specs, per-bucket counts, repo-wide lived-in-ratio (lived-in / total).
3. **Lived-in-ratio per scope** — table showing which scopes are most/least active.
4. **Top edited in window** — the 10 specs with most edits in the last N days.
5. **Top lived-in specs** — the 10 specs with most distinct authors over lifetime.
6. **Abandoned specs** — specs older than the recency window with 0 edits within it. Action queue for re-validation or removal.
7. **Write-once specs** — specs with only one ever-editor. May be deliberate (drafts in progress) or warning (no-one validated the content).

### Step 5 — Return digest

- Repo-wide lived-in-ratio + scope with the highest.
- Most-edited spec this window.
- Abandoned spec count.
- Link to the cached file.

### Extension points

- **Recency window** — default 90 days.
- **Lived-in threshold** — default 2 distinct authors; adopters may raise.
- **Excluded paths** — adopters may exclude generated outputs, templates, or content folders from the scan.
- **Canonicalisation source** — same as contributor-activity.

## What is not prescribed

- **What to do with abandoned specs.** Surfacing is the tool's job; deciding whether to refresh, archive, or delete is the adopter's.
- **Lines-changed metrics.** Volume of edit isn't proxied by line count; commit count is the cleaner signal.
- **Whether template files (e.g. `_template/spec.md`) count.** Adopter call — templates often have a low edit count by design.

## Rationale

Adoption of a spec-driven repository isn't measured by file count; it's measured by lived-in-ness. The most diagnostic failure mode is the repo that accumulates specs no-one re-reads — counts go up, decisions migrate to side channels anyway, and the surface becomes a write-only archive. This tool surfaces that pattern at file granularity, aggregated to scope. Combined with [`contributor-activity`](../contributor-activity/spec.md) (the *who*) and [`inbox-health`](../inbox-health/spec.md) (the *response*), it completes the adoption picture.

## Adoption

Adopters activate `spec-activity` by declaring `capabilities.observability.tool_extensions.spec-activity` in their manifest, writing the tool extension, and wiring a relay. Worked example: an adopter's extension at `.open-org-spec/extensions/observability/spec-activity/spec.md`.

## Related

- [`../spec.md`](../spec.md) — parent observability capability.
- [`../contributor-activity/spec.md`](../contributor-activity/spec.md) — sibling tool, the per-author view of the same activity.
- [`../owner-health/spec.md`](../owner-health/spec.md) — sibling tool; cross-reference for ownership context.
