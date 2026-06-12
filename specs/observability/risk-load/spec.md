# Risk-load

A tool of the open-org-spec observability capability. Aggregates the risk registry into two views — risks **by scope** and risks **by owner** — so a contributor can see where risk concentrates and who carries it without walking the registry by hand. Surfaces the metrics most diagnostic of an unmanaged risk surface: **unowned risks** (no accountable owner) and **risks awaiting disposition** (open past their escalation threshold with no recorded decision).

**Status:** Draft (0.1.0)
**Owner:** Javier Fernandez
**Type:** Command
**Reference implementation:** an adopter wires a relay at their command directory (e.g. `.claude/commands/risk-load.md`), with an extension at `.open-org-spec/extensions/observability/risk-load/spec.md`.

## Purpose

The risk registry records, per risk, a scope, an owner, a RAG status, a creation date, an escalation threshold, and a disposition date. Read one risk at a time, the registry is legible. Read in aggregate, it answers questions a single file cannot:

- **Where does risk concentrate?** The *by-scope* view shows which scopes carry the most risk and the most RED risk — the places that need attention first.
- **Who is carrying it?** The *by-owner* view shows risk count and RED count per owner, and how many scopes each owner's risk spreads across. An owner with RED risk spread across many scopes is a bus-factor and a load signal at once.
- **What is falling through?** Two summary counts are the highest-signal failures: **unowned risks** (no one is accountable) and **risks awaiting disposition** (open past their escalation threshold with no decision recorded). Both are invisible to file-level reading and both are quality failures.

## Pattern

### Inputs

- **Risk registry** — `governance/catalogue/risks.yaml` (adopter-declared path). The generated catalogue produced by the `risk-at-scope` capability. Each entry carries `id`, `title`, `path`, `scope`, `rag`, `owner` (list), `status`, `created_at`, `escalation_threshold` (days), `disposition_at`.
- **Scope registry** — `governance/catalogue/scopes.yaml` (adopter-declared path). The generated catalogue produced by the scope-registry. Each entry carries `type`, `slug`, `path`, `lead`, `feedback_inbox`, `status`. Used to resolve a risk's `scope` field to a scope lead and feedback inbox, and to label scopes by type.
- **Scope tree** — declared by the adopter's observability capability extension; used only to confirm which scope types are in view.

This tool depends on the `risk-at-scope` capability being active. It degrades gracefully when the scope registry is absent (see *Graceful fallback*).

### Step 1 — Load the registry

Read `risks.yaml`. Filter to open risks for the load views (`status: open`); count mitigated, accepted, and closed risks separately for context but do not carry them into the load tables. Each risk's `scope` field is a `type/slug` reference (or a bare slug — see fallback) used as the grouping key.

### Step 2 — Resolve scope metadata

Read `scopes.yaml`. For each distinct scope referenced by an open risk, look up the matching registry entry by `slug` (and `type` when present) to recover:

- the scope **lead** — displayed alongside the scope in the by-scope view as the escalation contact;
- the scope **feedback_inbox** — linked so a reader can route a concern about that scope's risk load to the right inbox.

A scope referenced by a risk but absent from the registry is shown with its slug only and flagged as an unregistered scope (a data-quality finding).

### Step 3 — Derive RAG

Use the registry's `rag` field as authoritative when present. Where the registry leaves RAG to be derived, derive it from age against the escalation threshold: an open risk whose age (`today − created_at`) exceeds `escalation_threshold` with an empty `disposition_at` is **RED**; one within a near-threshold band (adopter-declared, default the final third of the threshold window) is **AMBER**; otherwise **GREEN**.

### Step 4 — Build the by-scope view

For each scope with one or more open risks:

| Column | Value |
|---|---|
| Scope | `type/slug`, lead, feedback-inbox link |
| Total open | Count of open risks in the scope |
| RED / AMBER / GREEN | Count by RAG |
| Oldest open | Age in days of the oldest open risk, with its id and title |

Sort scopes by RED count descending, then total open descending.

### Step 5 — Build the by-owner view

Each risk's `owner` is a list; a risk with N owners contributes to N owner rows (co-owned risk is counted under each owner). For each distinct owner across open risks:

| Column | Value |
|---|---|
| Owner | Name as written in the registry |
| Total open | Count of open risks they own |
| RED | Count of their open risks that are RED |
| Scope spread | Count of distinct scopes their open risks touch, listed |

Sort owners by RED count descending, then scope spread descending. An owner whose RED risk spans multiple scopes is the load signal worth surfacing first.

### Step 6 — Compute the summary

- **Total open** — count of open risks.
- **RED count** — open risks deriving to RED.
- **AMBER count** — open risks deriving to AMBER.
- **Unowned count (critical)** — open risks whose `owner` list is empty or whose owner is unresolvable. Surfaced as the headline failure; an unowned risk has no path to disposition.
- **Awaiting-disposition count** — open risks whose age exceeds `escalation_threshold` and whose `disposition_at` is empty. These are past the point where a disposition decision was due and none has been recorded.

### Step 7 — Render

Cached markdown file at the adopter-declared observability output path. The file begins with a machine-readable YAML front-matter block carrying the headline metrics, followed by the generation header and the prose body.

```yaml
key_metrics:
  open_risks: N
  red_risks: N
  amber_risks: N
  unowned_risks: N
  awaiting_disposition: N
```

The file contains:

1. **Generation header** — `*Generated by /risk-load on YYYY-MM-DD HH:MM. Repo HEAD: <short-sha>. Re-run the command to refresh.*`
2. **Summary** — total open, RED, AMBER, unowned (critical), awaiting-disposition, with RAG traffic lights.
3. **Unowned risks** — the critical action queue. Each row: id, title, scope, age. Empty owner is the headline failure mode.
4. **Awaiting disposition** — open risks past escalation threshold with no disposition. Each row: id, title, scope, owner, days past threshold.
5. **By scope** — the table from Step 4. RED-heaviest scopes first.
6. **By owner** — the table from Step 5. RED-heaviest, widest-spread owners first.

### Step 8 — Return digest

- Total open, RED, AMBER counts.
- Unowned count and awaiting-disposition count — called out explicitly as the two failures.
- The single RED-heaviest scope and the single RED-heaviest owner.
- Link to the cached file.

### Graceful fallback

If `scopes.yaml` is absent or unreadable, the by-scope view groups solely on the risk's `scope` field (slug, or `type/slug` text verbatim). Lead and feedback-inbox columns are omitted, and the file notes that scope resolution is unavailable. The by-owner view, the summary, and both critical counts are unaffected — they need only `risks.yaml`. The tool never fails because the scope registry is missing; it reports less.

### Extension points

- **Registry paths** — `risk_registry_path` and `scope_registry_path`, defaulting to `governance/catalogue/risks.yaml` and `governance/catalogue/scopes.yaml`.
- **AMBER band** — the near-threshold fraction of the escalation window that derives to AMBER. Default: final third.
- **Awaiting-disposition basis** — whether the clock runs from `created_at + escalation_threshold` (default) or from a different field an adopter records.
- **Open-status vocabulary** — which `status` values count as open (default `open`); adopters whose registry uses additional in-flight statuses declare them.

## Artefacts

```yaml
artefacts:
  - id: risk-load-command
    type: file
    path: {{standard#adopter_command_dir}}/risk-load.md
    template: specs/observability/risk-load/command.md
    variables:
      - name: model
        source: config.yaml#capabilities.observability.model
        default: claude-sonnet-4-6
      - name: output_path
        source: config.yaml#capabilities.observability.risk_load.output_path
        default: governance/observability/risk-load.md
      - name: risk_registry_path
        source: config.yaml#capabilities.observability.risk_registry_path
        default: governance/catalogue/risks.yaml
      - name: scope_registry_path
        source: config.yaml#capabilities.observability.scope_registry_path
        default: governance/catalogue/scopes.yaml
      - name: amber_band_fraction
        source: config.yaml#capabilities.observability.risk_load.amber_band_fraction
        default: "0.33"
    check:
      type: file_contains
      value: 'canonical_spec_version: "{{canonical_spec_version}}"'
  - id: risk-load-workflow-contribution
    type: workflow_step
    contributes_to: specs/observability/suite.md
    description: >
      When the observability suite is active, /risk-load is added to the
      sequential tool run as the sixth tool. It writes only to its declared
      output path; the suite's post-execution write-scope validator covers it
      with no per-tool change. One suite execution refreshes risk-load.md
      alongside the other tools in a single commit.
    condition:
      type: config_equals
      config_path: capabilities.observability.suite.status
      equals: active
```

### `command.md` template

The relay wired at the adopter's command directory carries the canonical version stamp and the invocation contract:

```markdown
---
canonical_spec_version: "{{canonical_spec_version}}"
model: {{model}}
---

# /risk-load

Aggregate the risk registry into by-scope and by-owner load views and write
the result to `{{output_path}}`.

## Inputs
- Risk registry: `{{risk_registry_path}}`
- Scope registry: `{{scope_registry_path}}` (optional — degrade gracefully if absent)

## Steps
1. Load `{{risk_registry_path}}`; filter to open risks.
2. Resolve each risk's `scope` against `{{scope_registry_path}}` for lead and
   feedback inbox. If the scope registry is absent, group by the risk's `scope`
   field alone and omit lead/inbox columns.
3. Derive RAG from the registry `rag` field, or from age vs `escalation_threshold`
   (AMBER band fraction = {{amber_band_fraction}}).
4. Build the BY SCOPE view: per scope — total open, RED/AMBER/GREEN, oldest open age.
5. Build the BY OWNER view: per owner — total open, RED count, scope spread.
6. Compute summary: total open, RED, AMBER, unowned (critical),
   awaiting-disposition (open past escalation_threshold with empty disposition_at).
7. Write `{{output_path}}` with the key_metrics front-matter block, the
   generation header, then the summary and the two views.
8. Return a digest: headline counts, the two critical counts, the RED-heaviest
   scope and owner, and a link to the file.

## Guardrails
- Write only to `{{output_path}}`.
- Extract values only from the registry files. Do not infer or invent risks,
  owners, or RAG status not present in the data.
```

## What is not prescribed

- **Whether mitigated, accepted, or closed risks are tabulated.** The load views are about open risk; the standard counts non-open statuses only for context. An adopter who wants a closed-risk trend declares it.
- **RAG colour rendering.** Whether the markdown uses emoji traffic lights, text labels, or a renderer-specific block is an adopter choice.
- **Notification on RED or unowned.** This tool is pull-based and reports; it does not page an owner or open an issue. Acting on the counts is a layer-2 concern, deferred per the parent capability.
- **Cross-scope risk rollup.** Whether a programme-level risk that names child scopes is also counted against those children is left to the adopter's registry conventions; the tool groups on the `scope` field as written.

## Rationale

Risk is the metric family where *who is accountable* and *what is overdue* matter most, and both are exactly what a single risk file cannot show. Unowned and awaiting-disposition are the two failures that make a risk registry decorative rather than operative — a risk with no owner has no path to closure, and a risk past its escalation threshold with no disposition is one the org has stopped managing. Surfacing them as headline counts, alongside the by-scope and by-owner concentration views, turns the registry from a list into a load picture. The tool reuses the same `risk-at-scope` and scope-registry conventions the rest of the suite already depends on, so it adds no new convention pressure.

## Adoption

Adopters activate `risk-load` by declaring `capabilities.observability.tool_extensions.risk-load` in their manifest, writing the tool extension at `.open-org-spec/extensions/observability/risk-load/spec.md` (declaring registry paths, AMBER band, and output path), and wiring a relay at their command directory. When the observability suite is active, `/risk-load` joins the sequential run as the sixth tool with no per-tool security change — the suite's write-scope validator already covers its single output path.

## Related

- [`../spec.md`](../spec.md) — parent observability capability; the risk family is one of its six metric families.
- [`../suite.md`](../suite.md) — the automated suite; `/risk-load` runs as the sixth tool when the suite is active.
- [`../../governance-at-scope/spec.md`](../../governance-at-scope/spec.md) — the scope hierarchy this tool walks and groups by.
- [`../../feedback-inbox/spec.md`](../../feedback-inbox/spec.md) — the inbox convention used to link each scope's escalation route.
- [`../governance-pulse/spec.md`](../governance-pulse/spec.md) — composite tool whose risk-health metric this tool refines into dedicated by-scope and by-owner views.
- [`../owner-health/spec.md`](../owner-health/spec.md), [`../decision-health/spec.md`](../decision-health/spec.md), [`../inbox-health/spec.md`](../inbox-health/spec.md) — sibling tools.
