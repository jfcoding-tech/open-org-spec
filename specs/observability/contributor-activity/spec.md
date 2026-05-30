# Contributor-activity

A tool of the open-org-spec observability capability. Aggregates git author activity over a rolling 12-week window: distinct active authors per week, first-time-contributor count, and per-author commit volume. The leading and lagging indicators of adoption combined into one view.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** an adopter wires a relay at their command directory (e.g. `.claude/commands/contributor-activity.md`), with an extension at `.open-org-spec/extensions/observability/contributor-activity/spec.md`.

## Purpose

Adoption of a spec-driven repository is hard to measure intuitively. Two git-derivable signals are diagnostic:

- **First-time-contributor count over time.** A contributor's *first* commit indicates that onboarding succeeded — they got far enough to author something. Plateau or decline is a leading indicator of an awareness, friction, or trust problem.
- **Active-author count over time.** Distinct authors per week (or month). The lagging indicator of whether contributors *stay* — the surface earns its keep only when people return.

This tool produces both in one cached view, with per-author detail showing whether activity is broadly distributed or concentrated. The output is the closest thing the repo has to an adoption baseline.

## Pattern

### Inputs

- **Git log** — the canonical source.
- **People resolution** — the [`people-at-scope`](../../people/spec.md) capability, plus the adopter's contributor-identity convention (e.g. `.claude/contributor-modes.md`) for resolving `<login>@users.noreply.github.com` style emails to canonical names.
- **Time windows** — declared by the adopter's extension. Defaults: 12 weeks for the activity series, lifetime for first-time-contributor detection.

### Step 1 — Collect raw author signals

For the rolling window, run `git log --since="<N weeks ago>" --format='<commit-date>|<author-name>|<author-email>'` and parse into (date, author-name, author-email) tuples. Group by ISO week (Monday-start).

For the first-time-contributor signal, run `git log --reverse --format='%ae|%an|%ci'` over the whole history; the first appearance of each unique email is that author's join date.

### Step 2 — Canonicalise authors

Each author has potentially multiple `git config user.name` / `user.email` variants. Resolve to canonical name via:

1. **People roster lookup.** If the email matches a `people.md` entry's listed `git user.name` / `email`, use the canonical full name.
2. **Contributor-modes lookup.** If the adopter declares a contributor-modes file (e.g. `.claude/contributor-modes.md`) that maps git identities to canonical names, use it.
3. **Alias collapse heuristic.** Group identities sharing a prefix or domain pattern (e.g. `<login>@users.noreply.github.com` and `<login>@<org-domain>` style names) when the prefix is unique within the repo.
4. **Fallback.** Use the git author-name verbatim.

Surface unresolved or ambiguously-resolved identities in a data-quality appendix.

### Step 3 — Aggregate

- **Weekly time series** — for each week in the window: count of distinct canonical authors who committed, count of new-this-week first-time-contributors, total commits.
- **Per-author totals** — for each canonical author with activity in the window: total commits, weeks active out of 12, span of work (top-3 scopes touched, derived from changed-file paths).
- **First-time-contributor list** — every canonical author with a first-ever commit inside the window, dated.

### Step 4 — Render

Cached markdown file with:

1. **Generation header.**
2. **Summary** — total distinct authors in window, count of first-time-contributors in window, median weekly active count, busiest week.
3. **Mermaid time series** — weekly active authors + new authors, stacked or paired bars over the 12 weeks.
4. **First-time contributors in window** — table: name, first-commit date, affiliation if resolved.
5. **Per-author table** — commits, weeks-active, top scopes. Sorted by descending commits.
6. **Unresolved-identity appendix** — git authors that did not match a `people.md` row or contributor-modes file. Data-quality nudge.

### Step 5 — Return digest

- Active authors this week (and last week, for trend).
- New first-time-contributors in window.
- Trend direction (rolling 4-week average vs prior 4-week average): growing, stable, declining.
- Link to the cached file.

### Extension points

- **Time-series window length** — default 12 weeks.
- **Week boundary** — default Monday-start ISO week.
- **Canonicalisation source** — adopters declare which files/conventions ground the identity resolution.
- **Scope-affinity reporting** — adopters declare which folder structure to use for "top scopes" per author.
- **Anonymisation** — adopters operating in regulated environments may declare that named authors are aggregated rather than listed individually.

## What is not prescribed

- **Hours per commit / lines-of-code metrics.** Inadvertent productivity-theatre measures. Not surfaced.
- **Contributor cohort retention curves.** Useful at scale; premature at small contributor counts. Defer to v1 if the data warrants.
- **Pull-request review activity.** Out of scope for v0 — many adopters work on direct commits, and the metric is not universally derivable.

## Rationale

The contributor count over time is the trend that matters most for a spec-driven repo's survival. A repo accumulating decisions, specs, and tooling that no-one returns to is a heavy artefact, not a living surface. The first-time-contributor count tells you whether onboarding works; the active count tells you whether the surface earns repeat visits. Both are git-derivable; no new conventions needed.

## Adoption

Adopters activate `contributor-activity` by declaring `capabilities.observability.tool_extensions.contributor-activity` in their manifest, writing the tool extension, and wiring a relay. Worked example: an adopter's extension at `.open-org-spec/extensions/observability/contributor-activity/spec.md`.

## Related

- [`../spec.md`](../spec.md) — parent observability capability.
- [`../../people/spec.md`](../../people/spec.md) — people-resolution dependency.
- [`../spec-touch/spec.md`](../spec-touch/spec.md) — sibling tool, the per-spec view of the same activity.
