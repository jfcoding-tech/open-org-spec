# Decision-flow

A tool of the open-org-spec observability capability. Aggregates the `decisions/` folders across all scopes into one view: how many decisions exist where, their status mix, age of unresolved decisions, and how often each decision is cited by other specs. Surfaces the two most diagnostic metrics for decision quality — *open decisions over age threshold* and *decision linkage*.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** an adopter wires a relay at their command directory (e.g. `.claude/commands/decision-flow.md`), with an extension at `.open-org-spec/extensions/observability/decision-flow/spec.md`.

## Purpose

The [`governance-at-scope`](../../governance-at-scope/spec.md) capability puts decision records (ADRs) in a `decisions/` folder at every governed scope. Each ADR carries a status (`proposed`, `accepted`, `superseded`, `dropped`) and a date.

The aggregate view answers two questions that file-level reading cannot:

- **Are decisions getting made?** Open-decisions-over-age-threshold lists proposed decisions sitting unresolved past a cutoff. Each is either being neglected or being implicitly decided in side channels — and either way is a quality failure.
- **Are decisions getting used?** Decision linkage counts how often each ADR is cross-referenced from other specs. Decisions never cited are either too new (recent) or unused (made and forgotten). The pattern across scopes reveals whether the spec-driven thesis — *decisions captured here get re-used* — actually holds.

## Pattern

### Inputs

- **Governance convention** — the [`governance-at-scope`](../../governance-at-scope/spec.md) capability must be active. This tool depends on `decisions/<YYYY-MM-DD>-<slug>.md` naming and a status field in each ADR.
- **Scope tree** — declared by the adopter's observability capability extension.
- **Age thresholds** — declared by the adopter's extension; default *fresh* (< 14d), *aging* (14–30d), *stale* (> 30d) for `proposed` decisions.

### Step 1 — Walk decisions folders

For each `decisions/` folder under the scope tree:

1. List every ADR file (exclude `README.md`, `TEMPLATE.md`).
2. Parse the date from the filename prefix (`YYYY-MM-DD-...`).
3. Parse the status field from the file header. The standard recognises `proposed`, `accepted`, `superseded`, `dropped`. If a `superseded` ADR names what it was superseded by, capture the reference.

### Step 2 — Compute linkage

For each ADR file, grep the rest of the repo for relative-path references to the file. Count distinct files that cite it. Cross-scope citations (ADR in scope A cited from scope B) are counted separately as a sign of decision re-use across scopes.

### Step 3 — Bucket and rank

- **Open decisions** — every ADR in `proposed` status, sorted by descending age. Past the *aging* threshold = surface as warning; past *stale* = action queue.
- **Decisions by scope** — count per scope, status mix, citation density.
- **Citation outliers** — top-N most-cited decisions (load-bearing) and bottom-N least-cited (potentially unused).

### Step 4 — Render

Cached markdown file with:

1. **Generation header.**
2. **Summary** — total ADRs, status mix, count past *aging* and *stale* thresholds, median citation density.
3. **Open decisions over age threshold** — the action queue. Oldest first.
4. **Per-scope decision flow** — table per scope: count by status, oldest open ADR, citation density.
5. **Most-cited decisions** — load-bearing ADRs (cited from 3+ other specs). Removing them creates ripple.
6. **Least-cited decisions** — ADRs older than 14 days with 0 citations. Either unused or under-referenced.
7. **Supersession chains** — pairs of ADRs where one supersedes the other. Indicator of healthy revisiting.

### Step 5 — Return digest

- Total ADRs and status mix.
- Count past *stale* threshold.
- Top-3 oldest open decisions.
- Most-cited decision and its citation count.
- Link to the cached file.

### Extension points

- **Status vocabulary** — adopters may add status values beyond the base set.
- **Filename pattern** — alternatives to `YYYY-MM-DD-<slug>.md`.
- **Age thresholds** for proposed decisions.
- **Citation-density "load-bearing" floor** — what counts as a heavily-cited decision.

## What is not prescribed

- **Whether ADRs without a status field are flagged.** The standard requires status; flagging missing-status entries as data-quality findings is opt-in for adopters.
- **Whether the tool tries to auto-detect supersession from filename patterns** (e.g. `2026-05-22-supersedes-2026-04-30-...`). Adopter call — the explicit field reference is more reliable.

## Rationale

Decisions are the artefact most tied to quality: a spec-driven org's value compounds only if decisions get made (resolved) and re-used (cited). This tool measures both. Open-decisions-over-threshold is the single highest-signal quality metric — unresolved decisions are the most common failure mode of governance, and they're invisible to file-level reading.

## Adoption

Adopters activate `decision-flow` by declaring `capabilities.observability.tool_extensions.decision-flow` in their manifest, writing the tool extension, and wiring a relay. Worked example: an adopter's extension at `.open-org-spec/extensions/observability/decision-flow/spec.md`.

## Related

- [`../spec.md`](../spec.md) — parent observability capability.
- [`../../governance-at-scope/spec.md`](../../governance-at-scope/spec.md) — the decisions convention this tool depends on.
- [`../owner-load/spec.md`](../owner-load/spec.md), [`../inbox-load/spec.md`](../inbox-load/spec.md) — sibling tools.
