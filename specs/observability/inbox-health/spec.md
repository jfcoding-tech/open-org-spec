# Inbox-health

A tool of the open-org-spec observability capability. Aggregates open `→ <name>` feedback entries across all `feedback.md` files in the repo, ranked by addressee and age. Surfaces the single most diagnostic metric for whether the surface is *responsive* — and therefore whether contributors will keep using it.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** an adopter wires a relay at their command directory (e.g. `.claude/commands/inbox-health.md`), with an extension at `.open-org-spec/extensions/observability/inbox-health/spec.md`.

## Purpose

The [`feedback-inbox`](../../feedback-inbox/spec.md) capability defines how contributors raise asks: a `→ <name>` heading in a scope's `feedback.md`. The convention works at file level — anyone reading one file can see what's owed.

The aggregate picture — *which addressees have asks waiting, for how long, across the whole repo* — is invisible from any one file. A contributor whose inbox quietly fills up while they answer side-channel pings is a leakage point: contributors who raised issues here and didn't get a response will route the next ask to Slack instead, and the surface loses adoption.

This tool answers two questions in one scan: *who has unanswered asks?* and *how old are they?*

## Pattern

### Inputs

- **Feedback-inbox convention** — the [`feedback-inbox`](../../feedback-inbox/spec.md) capability must be active. This tool depends on the `→ <addressee>` heading marker and the `[resolved YYYY-MM-DD]` resolution prefix.
- **Scope tree** — declared by the adopter's observability capability extension.
- **Aging thresholds** — declared by the adopter's extension; default escalation tiers are *fresh* (< 7d), *aging* (7–14d), *stale* (14–30d), *abandoned* (> 30d).

### Step 1 — Walk feedback files

For each `feedback.md` under the scope tree (excluding the standard's templates):

1. Find every heading matching the addressee pattern: `## YYYY-MM-DD → <addressee> — <title>` or `## YYYY-MM-DD | <author> → <addressee> — <title>` or the bullet form `- YYYY-MM-DD | <author> → <addressee> | <body>`. Variations are common; the implementation handles them.
2. Detect resolution: a `[resolved]` or `[resolved YYYY-MM-DD]` prefix anywhere in the heading marks an entry closed. Untagged entries are open.
3. Parse the addressee — may be a single name (`→ Jordan`), a comma/plus list (`→ Jordan + Alex`), or a broadcast (`→ platform team`).

### Step 2 — Resolve addressees

Cross-reference each addressee name against active `people.md` rosters per the [`people-at-scope`](../../people/spec.md) capability. First-name matches resolve to canonical full-name + affiliation; ambiguous matches surface unresolved.

Broadcast addressees (`platform team`, `everyone`) are kept as-is and grouped separately.

### Step 3 — Age and bucket

For each open entry: age = today − heading date. Bucket by the adopter's aging thresholds (default: fresh / aging / stale / abandoned).

### Step 4 — Render

Write a cached markdown file at the adopter's path. The output file must begin with a machine-readable YAML front-matter block containing these key metrics, followed by the prose body.

```yaml
key_metrics:
  open_entries: N
  stale_entries: N
  abandoned_entries: N
  mean_time_to_resolution_days: N.N
```

Default sections:

1. **Generation header** — timestamp, HEAD ref, refresh hint.
2. **Summary** — total open / total resolved (lifetime) / median age of open / aging-and-older count.
3. **Per-addressee load** — one row per named person with open entries: open count, oldest age, links to the entries.
4. **Stale and abandoned** — entries past the *stale* threshold, oldest-first. The action queue.
5. **Broadcasts** — open entries addressed to a group rather than a person.
6. **Recently resolved** — past 14 days, as a positive signal of where the surface is working.

### Step 5 — Return digest

The conversation-time digest:

- Total open across all inboxes; count past *aging* and *stale* thresholds.
- Top-3 addressees by open count.
- Up to 3 oldest stale-or-abandoned entries.
- Link to the cached file for the full view.

### Extension points

- **Addressee patterns** — variations beyond `→ <name>` (e.g. an adopter using `@name` or `Owner: <name>` in inbox entries).
- **Resolution markers** — the standard's default is `[resolved]` or `[resolved YYYY-MM-DD]`. Adopters may add equivalents.
- **Aging thresholds** — fresh / aging / stale / abandoned cut-offs.
- **Broadcast handling** — whether to surface broadcasts in the per-addressee load (by expanding to all named recipients) or only in the dedicated section.
- **Recently-resolved window** — default 14 days.

## What is not prescribed

- **Whether the tool nudges addressees** (e.g. opens a feedback entry asking why an item is stale). Push-side behaviour is layer-2; v0 is pull-only.
- **Whether broadcast entries count toward an addressee's load.** Adopter call — an adopter's extension may exclude them by default to avoid penalising people on broadcast lists they didn't opt into.
- **Whether resolved entries should be removed from the file** by an automated cleanup. Adopter call — an adopter may retain all entries (heading prefix flips, content stays).

## Rationale

Of the metric families the observability capability declares, inbox-health is the single most diagnostic for adoption. Contributor counts measure intake; response time measures whether the surface answers. The first time a contributor's ask goes unanswered here, they route the next one elsewhere. The aggregate view surfaces that pattern before it compounds.

## Adoption

Adopters activate `inbox-health` by declaring `capabilities.observability.tool_extensions.inbox-health` in their manifest, writing the tool extension, and wiring a relay. Worked example: an adopter's extension at `.open-org-spec/extensions/observability/inbox-health/spec.md`.

## Related

- [`../spec.md`](../spec.md) — parent observability capability.
- [`../../feedback-inbox/spec.md`](../../feedback-inbox/spec.md) — the inbox convention this tool depends on.
- [`../owner-health/spec.md`](../owner-health/spec.md) — sibling tool; shares scope-walking and people-resolution primitives.
