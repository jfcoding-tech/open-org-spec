---
change: risk-load
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Risk-load — risk health observability tool

## Intent

Add `risk-load` as the sixth tool of the `observability` capability. It reads the
risk registry (`governance/catalogue/risks.yaml`) and the scope registry
(`governance/catalogue/scopes.yaml`), then writes a single cached markdown view to
`governance/observability/risk-load.md` that aggregates risk health two ways:

1. **By scope** — risk count and RAG breakdown per scope, so a reader can see which
   scopes are carrying the most live exposure.
2. **By owner** — risk count and RAG breakdown per owner, so a reader can see where
   risk-disposition load is concentrated, and which risks have no owner at all.

The tool surfaces the headline governance signals from the risk corpus — total open
risks, RED/AMBER/GREEN counts, **unowned risks** (the critical signal), and risks
past their `escalation_threshold` awaiting disposition. It follows the standard
observability tool shape: pull-based, reads the live registry, writes a cached file
with a generation header, returns a digest to the invoking interface. When the scope
registry is absent it degrades to the by-owner view with a note, so an adopter who has
not activated `scope-registry` still gets value.

## Rationale

**Risk health was the one primary governance signal the observability suite did not
cover.** The other five tools each address a distinct dimension of organisational
health: `owner-health` covers accountability, `decision-health` covers decision flow,
`inbox-health` covers cross-boundary collaboration, `contributor-activity` covers
knowledge visibility, `spec-activity` covers the living record. Risk — what currently
threatens the org and whether it is being dispositioned — is as central a governance
signal as any of these, and it was the gap. A `risk-at-scope` corpus that nobody can
see in aggregate decays exactly the way risks decayed before the capability existed:
silently, in scattered files, until one goes RED and surprises someone. The whole
point of `risk-at-scope` is that RAG is derived and staleness is mechanical — but that
discipline only pays off if there is a view that aggregates the derived state across
scopes. `risk-load` is that view.

**The dual pivot mirrors `owner-health`, and it earns its place the same way.** A
by-scope view answers *where is the exposure concentrated* — which parts of the org
are carrying the most, or the reddest, live risk. A by-owner view answers *who is
carrying the disposition load* — and, more importantly, surfaces risks with no owner
at all. Two questions, two views, one scan over the registry. The by-owner pivot is
not just a fairness lens on workload; it is how the most actionable signal in the whole
tool — unowned risks — becomes visible. An unowned risk is one nobody is accountable
for dispositioning, which means its derived RAG will march to RED on the clock with no
one positioned to clear it.

**Unowned risks are a stop signal, not just an assignment signal.** This follows the
same reading the Governance Pulse reading guide applies to unowned scopes: the
reflexive response to an unowned risk is to assign someone, but that is often the wrong
move. If no one at the scope is willing to own a risk, the honest question is whether
the risk is real and still matters, or whether the work it attaches to should stop.
Assigning a nominal owner to clear the red signal is the same vanity move the
capability already forbids for manually-coloured RAG. The by-owner view names this
explicitly so the reader is prompted to ask *should this be owned, or should the
underlying work be stopped?* rather than reaching for the assignment reflex.

**Reading the registry, not walking the repo, is the right input.** Unlike
`owner-health`, which walks role headers scattered across every spec, the risk corpus
already has a machine-readable aggregation: the risk registry agent writes
`governance/catalogue/risks.yaml` with every risk's derived RAG, status, owner, and
scope. `risk-load` consumes that artefact rather than re-walking every `risks/`
folder. This keeps the tool cheap, keeps the derived RAG consistent with the
registry's own computation (no second, divergent derivation), and means the tool's
output is only as stale as the last registry run — which the generation header makes
visible.

**By-scope grouping is reliable now that every risk carries a `scope` field.** Before
the `risk-scope-field` change (v0.12.0), grouping programme-level risks by scope was
guesswork — the file path said only "programme", and routing by owner identity breaks
when a person leads multiple scopes. With `scope: <type>/<slug>` present on every risk
and resolvable through `scopes.yaml`, the by-scope pivot is a direct lookup rather than
an inference. This is what makes the by-scope view trustworthy enough to ship; without
it, the tool would have to fall back to path inference for exactly the cross-cutting
risks that most need an aggregate view.

## Delta

This adds a new tool spec under the `observability` capability. No change to the
parent capability spec, to `risk-at-scope`, or to any other tool.

### New spec: `specs/observability/risk-load/spec.md`

A tool spec following the `owner-health` shape. Key sections:

**Inputs**

- **Risk registry** — `governance/catalogue/risks.yaml`, produced by the
  `risk-at-scope` registry agent. The primary input. Each entry carries `id`,
  `title`, derived `rag`, `status`, `owner` (possibly multiple), `scope`,
  `escalation_threshold`, and `disposition_at`.
- **Scope registry** — `governance/catalogue/scopes.yaml`, produced by the
  `scope-registry` capability. Resolves each risk's `scope` reference to a
  human-readable scope label. Optional — see graceful fallback.
- **Output path** — declared by the adopter's observability capability extension;
  defaults to `governance/observability/risk-load.md`.

**Step 1 — Load and validate the registry.** Read `risks.yaml`. For each risk,
recompute the derived RAG from `status`, filename/creation date, and
`escalation_threshold` per the `risk-at-scope` RAG derivation rules; if the cached
`rag` in the registry disagrees, prefer the recomputed value and note the divergence
as a warning (a stale registry is a `warning`, not a contradiction — same rule the
capability applies to cached RAG). Exclude terminal risks from the "open" counts but
retain them for historical totals where useful.

**Step 2 — Resolve scopes.** If `scope-registry` is active and `scopes.yaml` exists,
resolve each risk's `scope` field to its catalogue label. If `scopes.yaml` is absent
or `scope-registry` is inactive, skip the by-scope pivot, emit the by-owner view only,
and prefix the output with a note explaining the degraded mode.

**Step 3 — Aggregate two pivots.**

- **By scope** — group risks by resolved scope. Per scope: total open risks, and a
  RED / AMBER / GREEN count. Sort by descending RED count, then descending open count
  (reddest, heaviest scopes first).
- **By owner** — group risks by `owner`. A multi-owner risk appears under each owner
  (it is shared disposition load). Per owner: total open risks and a RED / AMBER /
  GREEN count. Risks with no `owner` are collected into a dedicated **Unowned** group,
  surfaced first regardless of count.

**Step 4 — Render.** Write the markdown file at the declared output path. The file
begins with a machine-readable `key_metrics` front-matter block, then the generation
header line, then the prose body.

```yaml
key_metrics:
  open_risks: N
  red_risks: N
  amber_risks: N
  green_risks: N
  unowned_risks: N
  awaiting_disposition: N
```

Body structure:

1. **Generation header** — *"Generated by `/risk-load` on YYYY-MM-DD HH:MM. Repo HEAD:
   `<short-sha>`. Re-run the command to refresh."*
2. **Summary block** — total open risks; RED / AMBER / GREEN counts; unowned-risk count
   (called out as the critical signal); count of risks past `escalation_threshold`
   awaiting disposition.
3. **By-scope section** — one row per scope, RAG breakdown, sorted reddest-first.
   Omitted (with a note) in degraded mode.
4. **By-owner section** — Unowned group first, then one sub-section per owner with their
   risks and RAG breakdown.

**Step 5 — Return digest.** Headline numbers (open / RED / unowned / awaiting
disposition), the single heaviest scope and heaviest owner, the list of unowned-risk
ids, and a link to the cached file.

**Reading guide entry.** A short reading-guide block consistent with the Governance
Pulse reading guide: what risk-load measures, what healthy and concerning states look
like, what action each signal calls for — with the explicit framing that unowned risks
are stop-or-own candidates, not assign-by-reflex tasks.

**Extension points** — output filename (default `risk-load.md`); whether to include a
RAG-by-scope mermaid/summary chart; sort order overrides; whether terminal risks appear
in any historical totals; the staleness/age columns surfaced per risk.

**Graceful fallback** — when `scopes.yaml` is absent, the by-owner view ships alone with
an explanatory note. When `risks.yaml` is absent entirely, the tool reports that no risk
registry exists and points the reader at `risk-at-scope` activation.

### Manifest and wiring (adopter side, illustrative — not part of the standard delta)

An adopter adopts `risk-load` by declaring
`capabilities.observability.tool_extensions.risk-load` in their manifest, writing the
tool extension at `.open-org-spec/extensions/observability/risk-load/spec.md`, and
wiring a relay at their command directory (e.g. `.claude/commands/risk-load.md`). The
tool joins the observability suite as a sixth sequential tool when the suite is active.

## Acceptance scenarios

### By-scope view surfaces the heaviest scope

Given a `risks.yaml` with 4 open risks scoped to `cluster/product-development` (2 RED)
and 1 open risk scoped to `function/revenue` (0 RED)
When `/risk-load` runs with `scope-registry` active
Then the by-scope section lists `product-development` first with `4 open, 2 RED`
And the digest names `product-development` as the heaviest scope

### Unowned risks are surfaced as the critical signal

Given a `risks.yaml` containing two open risks with no `owner` field
When `/risk-load` runs
Then `key_metrics.unowned_risks` is `2`
And the by-owner section lists an **Unowned** group first, ahead of any owner
And the reading guide frames them as stop-or-own candidates, not assignment tasks

### Risk past escalation threshold is counted as awaiting disposition

Given an open risk whose `age >= escalation_threshold` (derives to RED on the age criterion)
When `/risk-load` runs
Then it is included in `key_metrics.awaiting_disposition`
And it appears RED in both the by-scope and by-owner pivots

### Graceful fallback when the scope registry is absent

Given a repo with `risks.yaml` present but no `governance/catalogue/scopes.yaml`
When `/risk-load` runs
Then the output contains the by-owner view only
And a note at the top explains that the by-scope view is unavailable because the scope
registry is not active

### Multi-owner risk appears under each owner

Given an open risk with `owner: [Yaiza Temprado, Howard]`
When `/risk-load` runs
Then the risk appears in both Yaiza's and Howard's by-owner sub-sections
And it is counted in each owner's open-risk total (shared disposition load)

### Stale cached RAG in the registry is recomputed, not trusted

Given a risk in `risks.yaml` cached as `rag: GREEN` whose `age` now exceeds its
`escalation_threshold`
When `/risk-load` runs
Then the tool recomputes the RAG to RED, renders it as RED, and emits a warning that the
registry's cached value was stale

### Digest returned to the invoking interface

Given any populated `risks.yaml`
When `/risk-load` runs
Then the caller receives a short digest with open / RED / unowned / awaiting-disposition
counts, the heaviest scope, the heaviest owner, the unowned-risk ids, and a link to
`governance/observability/risk-load.md`

## Related

- `specs/observability/spec.md` — parent observability capability; the tool follows its
  pull-based, cached-output, generation-header, digest shape.
- `specs/observability/owner-health/spec.md` — sibling tool; `risk-load` reuses its
  dual-pivot design (by-scope / by-owner) and digest convention.
- `specs/observability/suite.md` — `risk-load` joins the suite as a sixth sequential
  tool when the suite is active.
- `specs/observability/stakeholder-report/spec.md` — the Governance Pulse reading guide;
  `risk-load`'s reading-guide entry follows the same what-it-measures / healthy /
  concerning / action shape and the stop-or-own framing for unowned items.
- `specs/risk-at-scope/spec.md` — source of the risk corpus, the derived-RAG rules, and
  the registry agent that produces `risks.yaml`.
- `proposals/risk-scope-field.md` — the `scope` field that makes the by-scope pivot a
  direct lookup rather than an inference.
- `proposals/scope-registry.md` — defines `scopes.yaml`, which resolves each risk's
  scope reference to a label; optional dependency for the by-scope view.
