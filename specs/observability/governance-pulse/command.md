---
description: Generate the Governance Pulse — a self-contained HTML stakeholder governance report from observability outputs
owner: Javier Fernandez
canonical_spec: open-org-spec/specs/observability/governance-pulse/spec.md
canonical_spec_version: "{{canonical_spec_version}}"
execution_context: claude-code
---

# /governance-pulse

Generates the **{{title}}** — a self-contained HTML governance health report for {{organisation}}. Reads from existing observability output files; does **not** re-run observability tools. Produces a single portable HTML file that opens in any browser without an internet connection and can be emailed or shared without requiring repository access.

Default variable values (substituted by `/adhere-to tooling` from the adopter's manifest extension):

| Variable | Default |
|---|---|
| `{{title}}` | `Governance Pulse` |
| `{{organisation}}` | from `config.yaml` `owner.name` |
| `{{output_path}}` | `governance/observability/governance-pulse.html` |
| `{{catalogue_path}}` | `governance/catalogue` |
| `{{model}}` | `claude-sonnet-4-6` |
| `{{stale_decision_threshold}}` | `14` |
| `{{ownership_coverage_threshold}}` | `80` |

---

## Execution logic

### Step 0 — Pre-flight

Before reading any file, verify the six upstream output files exist. If any are absent, continue with a `—` placeholder for that section's metrics — do not abort. Note which files were missing in the footer of the generated report.

Required files:
- `governance/observability/owner-load.md`
- `governance/observability/inbox-load.md`
- `governance/observability/decision-health.md`
- `governance/observability/contributor-activity.md`
- `governance/observability/spec-touch.md`
- `governance/observability/risk-load.md`

### Step 1 — Read all observability output files

Read the following files in full:

1. `governance/observability/owner-load.md`
2. `governance/observability/inbox-load.md`
3. `governance/observability/decision-health.md`
4. `governance/observability/contributor-activity.md`
5. `governance/observability/spec-touch.md`
6. `governance/observability/risk-load.md` (if absent, fall back to `governance/catalogue/risks.yaml`, then `governance/risk-registry.yaml`)

Each file carries a `generated:` timestamp in its front-matter or header. Record the timestamp for each file — render it per section in the report so readers know which dimensions are fresh and which are from a prior run.

If a file is missing or contains no timestamp, render that section with `—` for all metrics and a note: "Data not yet available — run the relevant observability command to generate."

### Step 2 — Read catalogue for ownership coverage

Read `{{catalogue_path}}/specs.yaml`. Count:
- Total spec entries
- Owned entries (`owner` field non-empty, not `TBD`, not blank)
- Unowned entries (empty, absent, or `TBD`)

Compute: **ownership coverage % = (owned / total) × 100**, rounded to 1 decimal place.

Also read `{{catalogue_path}}/scopes.yaml` if present to enumerate scope names for the per-scope breakdown.

Flag amber if below {{ownership_coverage_threshold}}%.

### Step 3 — Read decision metrics from pre-generated file

Read `governance/observability/decision-health.md` in full. Extract from its content:
- Total decisions
- Status mix (count by status value)
- Stale proposed decisions (>{{stale_decision_threshold}} days open)
- Median time-to-decision
- Most-cited decision (use `—` if not present in the file)

If `governance/catalogue/decisions.yaml` is present, also read it to cross-check total decision count.

Use `—` for any metric that cannot be read from the pre-generated file. Do **not** walk raw decision files directly.

If `decision-health.md` is absent or contains no timestamp, render the Decision velocity section with `—` for all metrics and a note: "Data not yet available — run /decision-health to generate."

### Step 4 — Read feedback responsiveness metrics from pre-generated file

Read `governance/observability/inbox-load.md` in full. Extract from its content:
- Total open entries
- Stale entries (>14 days unresolved)
- Abandoned entries (>30 days unresolved)
- Recently resolved (last 14 days)
- Highest-load addressee (person with most unresolved entries)
- Open entries by addressee (for chart data, top 6)

Do **not** walk `**/feedback.md` files directly across the repository. All inbox metrics must be read exclusively from `governance/observability/inbox-load.md`.

If `inbox-load.md` is absent or contains no timestamp, render the Inbox responsiveness section with `—` for all metrics and a note: "Data not yet available — run /inbox-load to generate."

### Step 5 — Compute the 6 metric groups

**Group 1 — Ownership health**
- Coverage % (from Step 2)
- Unique named people across all owner/lead/approver headers
- Role occurrences by person (top 5 by count)
- Bus-factor warnings: scopes where exactly one person holds all roles with no co-steward or approver
- Unresolved headers: role headers that could not be matched to a known person

**Group 2 — Decision health**
- Total decisions
- Status mix
- Stale proposed decisions count (>{{stale_decision_threshold}} days)
- Most-cited decision
- Median time-to-decision

**Group 3 — Feedback responsiveness**
- Total open entries
- Stale entries (>14 days unresolved)
- Abandoned entries (>30 days unresolved)
- Recently resolved (last 14 days)
- Highest-load addressee

**Group 4 — Contributor engagement**
- Active / session-only / no-activity counts
- Engagement rate (active ÷ total)
- Report `—` for all if `contributor-activity.md` is a placeholder or absent

**Group 5 — Spec surface health (lived-in ratio)**
- Total specs
- Lived-in (≥2 distinct authors in last 90 days)
- Stable (1 author only in last 90 days)
- Untouched / abandoned (no activity >90 days)
- Lived-in ratio % = (lived-in / total) × 100
- Top scope by lived-in ratio
- New specs since last report
- Top-edited spec

**Group 6 — Risk health**
- Read `governance/observability/risk-load.md` (fall back to `governance/catalogue/risks.yaml`, then `governance/risk-registry.yaml` if absent)
- Total risks in registry
- Open risks (`status: open`)
- RED risks (open with `rag: RED`)
- AMBER risks (open with `rag: AMBER`)
- Unowned risks (open with empty `owner` list or `owner: []`)
- Risks awaiting disposition: open risks where `disposition_at` is non-empty and older than today
- Risks by scope: group open risks by their `scope` field

If no risk registry file is found, render Group 6 with `—` for all metrics and note "risk-at-scope capability not active."

### Step 6 — Generate the HTML report

Write a single self-contained HTML file to `{{output_path}}`.

#### Hard requirements

- **100% self-contained.** No external URLs. No CDN links. No external fonts. No JavaScript libraries fetched at runtime. All styling via `<style>` block in `<head>`. All charts as inline SVG. All interactivity (if any) as inline `<script>`.
- **Print-friendly.** `@media print` CSS block hides interactive elements; preserves all metric content.
- **Accessible.** `<title>` element, `lang="en"` on `<html>`, semantic heading hierarchy (`h1`→`h2`→`h3`), `aria-label` on SVG charts.
- **No fabricated data.** Display `—` for any metric that cannot be computed. Never invent a number.

#### Visual design system

Colours:
- Primary: `#0066CC`
- Dark accent: `#004499`
- Light background: `#E8F0FB`
- Body text: `#333333`
- Secondary text: `#666666`
- Card background: `#FFFFFF`
- Page background: `#F5F7FA`
- Green (healthy): `#2E7D32` background `#E8F5E9`
- Amber (warning): `#E65100` background `#FFF3E0`
- Red (critical): `#B71C1C` background `#FFEBEE`

Typography: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`

Layout:
- Single-column, `max-width: 900px`, centred, `32px` horizontal padding
- Card component: `background: #fff`, `box-shadow: 0 1px 4px rgba(0,0,0,0.08)`, `padding: 20px`, `border-radius: 8px`, `border-left: 4px solid #0066CC`
- Stat block: large number in `#0066CC` (`font-size: 2rem`, `font-weight: 700`), small label below in `#666666` (`font-size: 0.8rem`, `text-transform: uppercase`, `letter-spacing: 0.05em`)

Badge CSS classes:
```css
.badge-healthy { background: #E8F5E9; color: #2E7D32; padding: 2px 10px; border-radius: 12px; font-size: 0.8rem; font-weight: 600; }
.badge-warning { background: #FFF3E0; color: #E65100; padding: 2px 10px; border-radius: 12px; font-size: 0.8rem; font-weight: 600; }
.badge-critical { background: #FFEBEE; color: #B71C1C; padding: 2px 10px; border-radius: 12px; font-size: 0.8rem; font-weight: 600; }
```

#### HTML structure

```
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}} — {{organisation}}</title>
    <style> ... all CSS inline ... </style>
  </head>
  <body>
    <header>          ← organisation name, report title, period, generated date
    <section id="preamble">   ← "How to read this report"
    <section id="ownership">  ← Group 1
    <section id="decisions">  ← Group 2
    <section id="feedback">   ← Group 3
    <section id="contributors"> ← Group 4
    <section id="spec-touch"> ← Group 5
    <section id="risks">      ← Group 6
    <section id="reading-guide"> ← full reading guide (all five metric families)
    <footer>          ← generation timestamp, source files, disclaimer
  </body>
</html>
```

#### `<header>` content

```html
<header style="background: #0066CC; color: white; padding: 32px; margin-bottom: 32px;">
  <div style="max-width: 900px; margin: 0 auto;">
    <p style="margin: 0 0 8px; font-size: 0.9rem; opacity: 0.8;">{{organisation}}</p>
    <h1 style="margin: 0 0 8px; font-size: 2rem; font-weight: 700;">{{title}}</h1>
    <p style="margin: 0; opacity: 0.8;">Period: last 30 days &nbsp;·&nbsp; Generated: <strong>[TODAY DATE]</strong></p>
  </div>
</header>
```

#### `<section id="preamble">` — "How to read this report"

This preamble must appear as the first section after the header, before any metrics. It is written in plain language for a non-technical executive audience.

Write the following content verbatim (adjust {{organisation}} and {{title}}):

---

**What this report is**

The {{title}} is a weekly pulse on how well {{organisation}} is governing itself. It translates six operational signals into plain language: is the right work owned? Are decisions being made? Is feedback flowing? Is the team contributing to a shared operating model? Is the written record staying current? Are risks being managed?

It does not measure delivery — whether sprints are completing, features are shipping, or revenue is growing. It measures the *conditions* that allow delivery to stay healthy over time: clear ownership, unblocked decisions, open feedback channels, a living written record.

**The five governance dimensions**

Each section of this report addresses one dimension of organisational health:

| Section | Governance dimension | The question it answers |
|---|---|---|
| Accountability coverage | Ownership | Does every piece of work have a named, accountable lead? |
| Decision velocity | Execution efficiency | Are decisions being made fast enough to unblock delivery? |
| Inbox responsiveness | Collaboration quality | Is feedback flowing freely across team boundaries? |
| Contribution trend | Knowledge visibility | Is the org's operating knowledge being made explicit and kept current? |
| Spec activity | Living record | Does the written description of how we work still reflect reality? |
| Risk health | Risk visibility | Are risks known, owned, and being actioned? |

**How to use it**

- A **green** badge means the dimension is healthy — no action needed.
- An **amber** badge means something needs attention — not urgent, but should be addressed this sprint or this fortnight.
- A **red** badge means something needs to be resolved now — it is either blocking others or represents a gap the org should not tolerate.

Each section includes a **Reading guide** that explains what the metric means in context — what "healthy" looks like, what "concerning" signals, and who should act.

**What this report does not cover**

This report is generated from the organisation's written operating model — the specs, decisions, feedback inboxes, and risk registers that describe how the org works. It does not analyse data in product systems, financial records, or communication tools. If a piece of work is not described in the operating model, it will not appear here.

---

#### `<section id="ownership">` — Accountability coverage

Section heading: **Accountability coverage**
Sub-heading: *Does every piece of work have a named lead?*
Data freshness label: "Data from owner-load.md · last generated: [timestamp from file]"

If `owner-load.md` is absent or has no timestamp, render all ownership metrics as `—` and show: "Data not yet available — run /owner-load to generate."

Stat blocks (horizontal row of 4):
1. Coverage % with badge (amber if < {{ownership_coverage_threshold}}%)
2. Total specs in catalogue
3. Owned specs count
4. Bus-factor warnings count (amber badge if > 0)

Horizontal bar chart — inline SVG:
- Title: "Top people by role count (top 5)"
- Width: 560, height: 180
- Left margin: 160px for names
- Max bar width: 380px
- Bar colour: `#0066CC`
- Bars labelled with count on right
- `aria-label="Bar chart: top 5 people by governance role count"`

If bus-factor warnings > 0: render a warnings card with amber left border listing the flagged scopes.

If unresolved headers > 0: render a note card listing the headers that could not be matched to a person.

**Reading guide for this section (embed inline, collapsible or visible):**

> **What it measures:** the percentage of active scopes that have a named, accountable lead. Derived from ownership headers across all governed specs.
>
> **Healthy:** every active scope has a named lead. The org knows who is accountable for every piece of work.
>
> **Concerning:** one or more active scopes have no named lead. These scopes are ungoverned — decisions about them cannot be made, feedback routed to them has no recipient, and the work they describe has no one accountable for its accuracy.
>
> **Action:** unowned scopes are not just a governance gap — they are candidates to be stopped. If no one is willing to own a scope, it is a signal that the work it represents may no longer be needed or prioritised. The governance owner should ask: *does this scope need an owner, or does it need to be closed?* Assigning a nominal owner to avoid the red signal is the wrong response.
>
> **Who acts:** governance owner (to assign or close) or the org lead who would logically own the scope.

#### `<section id="decisions">` — Decision velocity

Section heading: **Decision velocity**
Sub-heading: *Are decisions being made fast enough to unblock delivery?*
Data freshness label: "Data from decision-health.md · last generated: [timestamp from file]"

If `decision-health.md` is absent or has no timestamp, render all decision metrics as `—` and show: "Data not yet available — run /decision-health to generate."

Stat blocks (horizontal row of 4):
1. Total decisions
2. Stale proposed (amber badge if > 0)
3. Median days to decision (or `—`)
4. Decided in last 30 days

If stale proposed > 0: render a table of stale decisions with columns: Decision title (filename or inferred title), Days open, Owner (from decision file `Owner:` field or `—`).

**Reading guide for this section:**

> **What it measures:** how quickly open decisions close, and how many are currently stalled past the {{stale_decision_threshold}}-day threshold. Derived from decision records across all governed scopes.
>
> **Healthy:** decisions are closing at a regular cadence. The gap between a decision being opened and the `decided_at` date is short. No decisions have been open past the staleness threshold without an explicit deferral.
>
> **Concerning:** decisions are open and ageing. Work that depends on those decisions is blocked, even if the blockage is not yet visible in the delivery system.
>
> **Action:** decision velocity is the most direct indicator of organisational execution efficiency. Fast delivery requires two things: speed of execution and speed of decision. Organisations that are slow to decide are slow to deliver, even when their teams are executing well. A stalled decision should be named by its owner: either decide it, explicitly defer it with a rationale and a review date, or close it as no longer needed. Leaving it open is not a neutral choice — it is invisible blocking.
>
> **Who acts:** the decision's declared owner. If no owner is declared, the scope's governance owner routes to the right person.

#### `<section id="feedback">` — Inbox responsiveness

Section heading: **Inbox responsiveness**
Sub-heading: *Is feedback flowing freely across team boundaries?*
Data freshness label: "Data from inbox-load.md · last generated: [timestamp from file]"

If `inbox-load.md` is absent or has no timestamp, render all inbox metrics as `—` and show: "Data not yet available — run /inbox-load to generate."

Stat blocks (horizontal row of 4):
1. Total open entries
2. Stale (>14 days) with amber badge if > 0
3. Abandoned (>30 days) with red badge if > 0
4. Resolved last 14 days

Horizontal bar chart — inline SVG:
- Title: "Open entries by addressee (top 6)"
- Width: 560, height: 220
- Left margin: 160px for names
- Max bar width: 380px
- Bar colour: `#0066CC`
- `aria-label="Bar chart: top 6 feedback addressees by open entry count"`

**Reading guide for this section:**

> **What it measures:** how many unresolved observations exist across the org's feedback inboxes. Derived from open entries in `feedback.md` files at every governed scope.
>
> **Healthy:** feedback entries are being read and resolved at a reasonable cadence. The organisation is processing the observations being made about its own work.
>
> **Concerning:** entries are accumulating unresolved. The feedback loop is broken.
>
> **Action:** the feedback inbox is not only an improvement channel — it is the organisation's primary collaboration surface. When a contributor writes into a scope's feedback inbox, they are attempting to influence the work of a person they do not directly manage. Inbox responsiveness is therefore a measure of how well the organisation collaborates across boundaries. A low responsiveness score does not mean people are unresponsive as individuals — it means the organisation has not created the conditions for cross-boundary influence to flow. The scope owner is the first responder; patterns of low responsiveness across many scopes signal a structural problem, not individual negligence.
>
> **Who acts:** each scope's owner (to resolve entries in their inbox). The governance owner reads the aggregate pattern.

#### `<section id="contributors">` — Contribution trend

Section heading: **Contribution trend**
Sub-heading: *Is the org's operating knowledge being made explicit and kept current?*
Data freshness label: "Data from contributor-activity.md · last generated: [timestamp from file]"

If `contributor-activity.md` is absent or has no timestamp, render all contributor metrics as `—` and show: "Data not yet available — run /contributor-activity to generate."

Stat blocks (horizontal row of 4):
1. Active contributors count
2. Session-only count (amber badge if > 20% of total)
3. No-activity count (amber badge if > 50% of total)
4. Engagement rate %

If `contributor-activity.md` is absent, a placeholder, or has no timestamp: render a single card "Contributor data not yet available — run /contributor-activity to generate." with all stats as `—`.

**Reading guide for this section:**

> **What it measures:** how many distinct contributors are writing to the operating model, how frequently, and whether the trend is rising, stable, or falling. Derived from git commit authorship and command-run data across governed paths.
>
> **Healthy:** contribution is distributed across multiple contributors and is consistent with the maturity of the work. New initiatives show rising contribution; stable programmes show consistent contribution; initiatives in maintenance show lower but non-zero contribution.
>
> **Concerning — two distinct states:**
> - *Low contribution on new or active work* — the org's knowledge is not being made explicit. Work is being done but not written down. The operating model is not functioning as a living record.
> - *Zero contribution on supposedly active work* — a scope may have been "installed": treated as finished and no longer evolved, even though the reality it describes has moved on. Installed specs are more dangerous than absent specs — they look authoritative but describe a past state.
>
> **Maturity read:** falling contribution is not always a warning. An initiative that started with high contribution and has settled into low but stable contribution has likely reached a healthy maintenance phase. The governance owner should distinguish between *maturing* (expected, positive) and *neglecting* (unexpected, concerning).
>
> **Who acts:** scope owners (to write down what they're doing). Governance owner (to distinguish maturity from neglect, and to ask whether installed specs need updating or closing).

#### `<section id="spec-touch">` — Spec activity

Section heading: **Spec activity**
Sub-heading: *Does the written description of how we work still reflect reality?*
Data freshness label: "Data from spec-touch.md · last generated: [timestamp from file]"

If `spec-touch.md` is absent or has no timestamp, render all spec activity metrics as `—` and show: "Data not yet available — run /spec-touch to generate."

Stat blocks (horizontal row of 4):
1. Total specs
2. Lived-in (≥2 authors)
3. Stable (1 author)
4. Lived-in ratio % (amber badge if < 20%)

If top-edited spec or abandoned specs are available: render them as named items in a card below the stat blocks.

**Reading guide for this section:**

> **What it measures:** how recently each spec was last meaningfully edited, and how many distinct people have contributed to it. Derived from git history per spec file.
>
> **Healthy:** specs are being updated as the work they describe evolves. The written record and the organisational reality are in sync. Multiple contributors are editing the same specs, indicating collective ownership rather than a single author's private document.
>
> **Concerning:** specs have not been touched in a long time relative to the staleness threshold.
>
> **Action:** a spec that is not being updated is one of two things: either the work it describes is genuinely stable (acceptable) or the spec is getting "installed" — the organisation has moved on but the document has been left behind as a historical artefact that still looks current. The distinction matters: a stable spec that accurately describes a stable reality is fine; an installed spec that no longer describes reality is misleading. The spec owner should ask: *does this spec still accurately describe how this part of the org works? If not, update it or close the scope.*
>
> **Who acts:** each spec's declared owner.

#### `<section id="risks">` — Risk health

Section heading: **Risk health**
Sub-heading: *Are risks known, owned, and being actioned?*
Data freshness label: "Data from risk-load.md · last generated: [timestamp from file]"

If `risk-load.md` is absent, fall back to `governance/catalogue/risks.yaml` then `governance/risk-registry.yaml`. If no risk source is found, render all risk metrics as `—` and show: "Data not yet available — run /risk-load to generate, or activate the risk-at-scope capability."

Stat blocks (horizontal row of 5):
1. Total risks in registry
2. Open risks count
3. RED risks count (red badge if > 0)
4. AMBER risks count (amber badge if > 0)
5. Unowned risks count (red badge if > 0)

If RED risks > 0: render a table with columns: ID, Title, Scope, Owner, Days open, Disposition. Title each row with a red left border. Sort by days open descending.

If risks awaiting disposition > 0: render an amber card listing them — these are risks where `disposition_at` date has passed and the risk is still open.

If unowned risks > 0: render a note card listing scopes with unowned risks.

Risks by scope breakdown: a compact table showing scope → open count → RED count → AMBER count.

**Reading guide for this section:**

> **What it measures:** the state of the organisation's risk register — how many risks are open, how many are at or past their escalation threshold, how many lack an owner, and how many are awaiting a disposition decision that has not been made.
>
> **Healthy:** risks are being tracked with owners. RED risks have named owners and active dispositions. Escalation thresholds are being honoured.
>
> **Concerning:** unowned risks (no one is watching them); risks past their escalation threshold with no disposition recorded; a high concentration of RED risks in one scope.
>
> **Action:** each open risk should have a named owner and a disposition date. If a risk is past its escalation threshold without a disposition, it should be escalated to the governance owner immediately. Unowned risks are the most dangerous — they are acknowledged problems with no one accountable for resolving them.
>
> **Who acts:** the risk's declared owner (for in-threshold risks). The scope's governance owner (for risks past threshold). The repo-wide governance owner (for unowned risks).

#### `<section id="reading-guide">` — Full reading guide

Section heading: **Reading guide**
Sub-heading: *What each metric means and what to do about it*

This section embeds the full reading guide from the Governance Pulse proposal. Write the following content verbatim, formatted as collapsible `<details><summary>` blocks — one per metric family — so readers can expand individual sections:

---

**Preamble to the reading guide:**

The Governance Pulse measures five dimensions of whether an organisation is operating well. They are not five independent dials — together they form a model of organisational health.

| Dimension | What it detects |
|---|---|
| Accountability | Is everything owned? |
| Execution efficiency | Are decisions unblocking delivery? |
| Collaboration quality | Is feedback flowing across boundaries? |
| Knowledge visibility | Is the org's knowledge being made explicit? |
| Living record | Does the written record still reflect reality? |

A sixth dimension — risk visibility — detects whether known risks are owned and being actioned.

---

`<details><summary>Accountability coverage</summary>`

**What it measures:** the percentage of active scopes — clusters, functions, projects, modules — that have a named, accountable lead. Derived from ownership headers across all governed specs.

**Healthy:** every active scope has a named lead. The org knows who is accountable for every piece of work.

**Concerning:** one or more active scopes have no named lead (`TBD` or absent). These scopes are ungoverned — decisions about them cannot be made, feedback routed to them has no recipient, and the work they describe has no one accountable for its accuracy.

**Action:** unowned scopes are not just a governance gap — they are candidates to be stopped. If no one is willing to own a scope, it is a signal that the work it represents may no longer be needed or prioritised. The governance owner should ask: *does this scope need an owner, or does it need to be closed?* Assigning a nominal owner to avoid the red signal is the wrong response.

**Who acts:** governance owner (to assign or close) or the org lead who would logically own the scope.

`</details>`

`<details><summary>Decision velocity</summary>`

**What it measures:** how quickly open decisions close, and how many are currently stalled past the adopter-declared staleness threshold. Derived from decision records across all governed scopes.

**Healthy:** decisions are closing at a regular cadence. The gap between a decision being opened and `decided_at` being recorded is short. No decisions have been open past the staleness threshold without an explicit deferral.

**Concerning:** decisions are open and ageing. Work that depends on those decisions is blocked, even if the blockage is not yet visible in the delivery system.

**Action:** decision velocity is the most direct indicator of organisational execution efficiency. Fast delivery requires two things: speed of execution and speed of decision. Organisations that are slow to decide are slow to deliver, even when their teams are executing well. A stalled decision should be named by its owner: either decide it, explicitly defer it with a rationale and a review date, or close it as no longer needed. Leaving it open is not a neutral choice — it is invisible blocking.

**Who acts:** the decision's declared owner. If no owner is declared, the scope's governance owner routes to the right person.

`</details>`

`<details><summary>Inbox responsiveness</summary>`

**What it measures:** how many unresolved observations exist across the org's feedback inboxes — `feedback.md` files at every governed scope. Derived from open (non-`[resolved]`) entries in feedback inboxes.

**Healthy:** feedback entries are being read and resolved at a reasonable cadence. The organisation is processing the observations being made about its own work.

**Concerning:** entries are accumulating unresolved. The feedback loop is broken.

**Action:** the feedback inbox is not only an improvement channel — it is the organisation's primary collaboration surface. When a contributor writes into a scope's feedback inbox, they are attempting to influence the work of a person they do not directly manage. Inbox responsiveness is therefore a measure of how well the organisation collaborates across boundaries. A low responsiveness score does not mean people are unresponsive as individuals — it means the organisation has not created the conditions for cross-boundary influence to flow. The scope owner is the first responder; patterns of low responsiveness across many scopes signal a structural problem, not individual negligence.

**Who acts:** each scope's owner (to resolve entries in their inbox). The governance owner reads the aggregate pattern.

`</details>`

`<details><summary>Contribution trend</summary>`

**What it measures:** how many distinct contributors are writing to the repo, how frequently, and whether the trend is rising, stable, or falling. Derived from git commit authorship across governed paths.

**Healthy:** contribution is distributed across multiple contributors and is consistent with the maturity of the work. New initiatives show rising contribution; stable programmes show consistent contribution; initiatives in maintenance show lower but non-zero contribution.

**Concerning — two different states, requiring different responses:**

- *Low contribution on new or active work* — the org's knowledge is not being made explicit. Work is being done but not written down. The repo is not functioning as the organisation's operating surface; it is a filing cabinet that nobody files in.
- *Zero contribution on supposedly active work* — a scope may have been "installed": treated as finished and no longer evolved, even though the reality it describes has moved on. Installed specs are more dangerous than absent specs — they look authoritative but describe a past state.

**Maturity read:** falling contribution is not always a warning. An initiative that started with high contribution and has settled into low but stable contribution has likely reached a healthy maintenance phase. The governance owner should distinguish between *maturing* (expected, positive) and *neglecting* (unexpected, concerning).

**Who acts:** scope owners (to write down what they're doing). Governance owner (to distinguish maturity from neglect, and to ask whether installed specs need updating or closing).

`</details>`

`<details><summary>Spec activity</summary>`

**What it measures:** how recently each spec was last meaningfully edited. Derived from git log per spec file.

**Healthy:** specs are being updated as the work they describe evolves. The written record and the organisational reality are in sync.

**Concerning:** specs have not been touched in a long time, relative to the adopter-declared staleness threshold.

**Action:** a spec that is not being updated is one of two things: either the work it describes is genuinely stable (which is acceptable) or the spec is getting "installed" — the organisation has moved on but the document has been left behind as a historical artefact that still looks current. The distinction matters: a stable spec that accurately describes a stable reality is fine; an installed spec that no longer describes reality is misleading. The spec owner should ask: *does this spec still accurately describe how this part of the org works? If not, update it or close the scope.*

**Who acts:** each spec's declared owner.

`</details>`

---

#### `<footer>` content

```html
<footer>
  <p><strong>Generated:</strong> [FULL TIMESTAMP WITH TIMEZONE]</p>
  <p><strong>Source files:</strong> governance/observability/owner-load.md (generated: [ts]) · inbox-load.md (generated: [ts]) · decision-health.md (generated: [ts]) · contributor-activity.md (generated: [ts]) · spec-touch.md (generated: [ts]) · risk-load.md (generated: [ts or MISSING])</p>
  <p><strong>Missing files:</strong> [list any files from Step 0 that were absent, or "none"]</p>
  <p>Not for external distribution. Internal governance report for {{organisation}}.</p>
</footer>
```

#### Threshold flags summary

The following thresholds determine badge colours:

| Metric | Amber threshold | Red threshold |
|---|---|---|
| Ownership coverage | below {{ownership_coverage_threshold}}% | n/a (flag amber only) |
| Bus-factor warnings | > 0 | n/a |
| Stale proposed decisions | > 0 | n/a |
| Abandoned feedback | n/a | > 0 |
| Lived-in ratio | < 20% | n/a |
| Contributors no-activity | > 50% of total | n/a |
| RED risks | n/a | > 0 |
| Unowned risks | n/a | > 0 |
| Risks awaiting disposition | > 0 | n/a |

### Step 7 — Log the invocation

Detect OS then call the pre-approved log script:

1. Run `uname -s` to detect OS (pre-approved, no prompt).
2. macOS / Linux: `bash governance/observability/command-log.sh /governance-pulse <files_read_count> true <outcome> {{model}} || true`
3. Windows: `powershell -File governance/observability/command-log.ps1 /governance-pulse <files_read_count> true <outcome> {{model}}; $true`

Where `<outcome>` is `success` if the HTML file was written without error, `partial` if one or more source files were absent, or `error` if the HTML file could not be written.

If neither log script exists, skip silently.

---

## Retry contract

If HTML generation fails (file write error, encoding error, permission error):
1. Retry once after logging the error to the digest.
2. If the second attempt fails, output the digest with `Output: FAILED — [error message]` and do not produce a partial file.

Do not retry on missing source files — treat absent files as expected and render `—` for those sections.

---

## Output

Return the following digest after the HTML file is written:

```
/governance-pulse complete.
Output: {{output_path}}
Generated: <YYYY-MM-DD HH:MM UTC>

Metrics snapshot:
  Ownership coverage:     <x>% (<owned>/<total> catalogue entries)  [HEALTHY|WARNING|—]
  Bus-factor warnings:    <n> scopes
  Open feedback:          <n> entries (<n> stale, <n> abandoned)     [HEALTHY|WARNING|CRITICAL]
  Decision queue:         <n> proposed (<n> stale)                   [HEALTHY|WARNING]
  Lived-in ratio:         <n>%                                       [HEALTHY|WARNING|—]
  Contributor engagement: <n> active / <n> session-only / <n> inactive
  Open risks:             <n> total (<n> RED, <n> AMBER, <n> unowned) [HEALTHY|WARNING|CRITICAL]

Source freshness:
  owner-load.md:          generated <timestamp or MISSING>
  inbox-load.md:          generated <timestamp or MISSING>
  decision-health.md:     generated <timestamp or MISSING>
  contributor-activity.md: generated <timestamp or MISSING>
  spec-touch.md:          generated <timestamp or MISSING>
  risk-load.md:           generated <timestamp or MISSING>
```
