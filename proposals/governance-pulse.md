---
change: governance-pulse
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Governance Pulse — rename and reading guide for the stakeholder report

## Intent

Two changes to the `stakeholder-report` capability:

1. **Rename the report title to "Governance Pulse."** The technical identifier (`stakeholder-report`, file paths, command names) stays unchanged. Only the display title changes.

2. **Add a `## Reading guide` section to the spec.** The reading guide defines — at the standard level — what each metric measures, what it means when it is healthy or concerning, and what action it should trigger. Adopters can extend or override the guide in their extension spec.

## Rationale

**"Stakeholder Report" describes the audience, not the purpose.** Every document is for stakeholders. The name gives no signal about what the reader will learn or why they should care. An adopter encountering it for the first time has no frame for what kind of information it contains.

**"Governance Pulse" communicates both cadence and purpose.** A pulse is a recurring, periodic signal that tells you whether the organism is alive and functioning. The Governance Pulse is exactly that: a weekly check on whether the org's operating model is working — whether the right things are owned, whether decisions are moving, whether the org is collaborating, whether the written record reflects reality. The name communicates all of this before the reader opens the document. Once the rationale is visible, the name is self-explanatory; unlike a generic label, it earns its meaning.

**The reading guide belongs in the standard because the metrics come from standard capabilities.** Each metric in the Governance Pulse is produced by a standard capability: `governance-at-scope` produces decision records; `feedback-inbox` produces the inbox entries; `people` produces ownership records; `tooling` produces contribution data; `project` and the spec capabilities produce spec-activity data. Because the metrics are standard-derived, the interpretation of what each metric means is also standard-level. An adopter who activates these capabilities and sees a red inbox-responsiveness signal should not have to invent what that means — the standard should tell them. Adopter extensions can refine thresholds and add org-specific protocols, but the base interpretation is generic and reusable.

**Together, the five metrics form a coherent model of organisational health.** They are not five independent dials. They address five distinct dimensions of whether an organisation is operating well:

1. **Accountability** — is everything owned?
2. **Execution efficiency** — are decisions unblocking delivery?
3. **Collaboration quality** — is feedback flowing across boundaries?
4. **Knowledge visibility** — is the org's knowledge being made explicit?
5. **Living record** — does the written record still reflect reality?

The reading guide makes this model visible to the reader. Without it, the report is a dashboard of numbers. With it, it is a diagnostic tool.

## Delta

### Change 1 — Rename display title

In `specs/observability/stakeholder-report/spec.md`:

- Change the document title from `# Stakeholder Report` to `# Governance Pulse`
- Add a note: *The technical identifier for this tool is `stakeholder-report` (file paths, command names, and manifest entries use this identifier). The display title is **Governance Pulse**.*
- The adopter's `title` extension point (declared in the observability extension) overrides the display title in the generated report.

No changes to file paths, command names, GHA workflow references, or manifest keys.

### Change 2 — Reading guide section

Add `## Reading guide` to `specs/observability/stakeholder-report/spec.md`, after the metric definitions and before `## What is not prescribed`.

The reading guide is structured as five metric families. Each entry covers: what it measures, what the healthy state looks like, what the concerning state signals, and what action it calls for.

---

#### Ownership

**What it measures:** the percentage of active scopes — clusters, functions, projects, modules — that have a named, accountable lead. Derived from `people.md` Lead tables across all governed scopes.

**Healthy:** every active scope has a named lead. The org knows who is accountable for every piece of work.

**Concerning:** one or more active scopes have no named lead (`TBD` or absent). These scopes are ungoverned — decisions about them cannot be made, feedback routed to them has no recipient, and the work they describe has no one accountable for its accuracy.

**Action:** unowned scopes are not just a governance gap — they are candidates to be stopped. If no one is willing to own a scope, it is a signal that the work it represents may no longer be needed or prioritised. The governance owner should ask: *does this scope need an owner, or does it need to be closed?* Assigning a nominal owner to avoid the red signal is the wrong response.

**Who acts:** governance owner (to assign or close) or the org lead who would logically own the scope.

---

#### Decision velocity

**What it measures:** how quickly open decisions close, and how many are currently stalled past the adopter-declared staleness threshold. Derived from decision records across all governed scopes.

**Healthy:** decisions are closing at a regular cadence. The gap between a decision being opened and `decided_at` being recorded is short. No decisions have been open past the staleness threshold without an explicit deferral.

**Concerning:** decisions are open and ageing. Work that depends on those decisions is blocked, even if the blockage is not yet visible in the delivery system.

**Action:** decision velocity is the most direct indicator of organisational execution efficiency. Fast delivery requires two things: speed of execution and speed of decision. Organisations that are slow to decide are slow to deliver, even when their teams are executing well. A stalled decision should be named by its owner: either decide it, explicitly defer it with a rationale and a review date, or close it as no longer needed. Leaving it open is not a neutral choice — it is invisible blocking.

**Who acts:** the decision's declared owner. If no owner is declared, the scope's governance owner routes to the right person.

---

#### Inbox responsiveness

**What it measures:** how many unresolved observations exist across the org's feedback inboxes — `feedback.md` files at every governed scope. Derived from open (non-`[resolved]`) entries in feedback inboxes.

**Healthy:** feedback entries are being read and resolved at a reasonable cadence. The organisation is processing the observations being made about its own work.

**Concerning:** entries are accumulating unresolved. The feedback loop is broken.

**Action:** the feedback inbox is not only an improvement channel — it is the organisation's primary collaboration surface. When a contributor writes into a scope's feedback inbox, they are attempting to influence the work of a person they do not directly manage. Inbox responsiveness is therefore a measure of how well the organisation collaborates across boundaries. A low responsiveness score does not mean people are unresponsive as individuals — it means the organisation has not created the conditions for cross-boundary influence to flow. The scope owner is the first responder; patterns of low responsiveness across many scopes signal a structural problem, not individual negligence.

**Who acts:** each scope's owner (to resolve entries in their inbox). The governance owner reads the aggregate pattern.

---

#### Contribution trend

**What it measures:** how many distinct contributors are writing to the repo, how frequently, and whether the trend is rising, stable, or falling. Derived from git commit authorship across governed paths.

**Healthy:** contribution is distributed across multiple contributors and is consistent with the maturity of the work. New initiatives show rising contribution; stable programmes show consistent contribution; initiatives in maintenance show lower but non-zero contribution.

**Concerning:** two different concerning states exist, and they require different responses:

- **Low contribution on new or active work** — the org's knowledge is not being made explicit. Work is being done but not written down. The repo is not functioning as the organisation's operating surface; it is a filing cabinet that nobody files in.
- **Zero contribution on supposedly active work** — a scope may have been "installed": treated as finished and no longer evolved, even though the reality it describes has moved on. Installed specs are more dangerous than absent specs — they look authoritative but describe a past state.

**Maturity read:** falling contribution is not always a warning. An initiative that started with high contribution and has settled into low but stable contribution has likely reached a healthy maintenance phase. The governance owner should distinguish between *maturing* (expected, positive) and *neglecting* (unexpected, concerning).

**Who acts:** scope owners (to write down what they're doing). Governance owner (to distinguish maturity from neglect, and to ask whether installed specs need updating or closing).

---

#### Spec activity

**What it measures:** how recently each spec was last meaningfully edited. Derived from git log per spec file.

**Healthy:** specs are being updated as the work they describe evolves. The written record and the organisational reality are in sync.

**Concerning:** specs have not been touched in a long time, relative to the adopter-declared staleness threshold.

**Action:** a spec that is not being updated is one of two things: either the work it describes is genuinely stable (which is acceptable) or the spec is getting "installed" — the organisation has moved on but the document has been left behind as a historical artefact that still looks current. The distinction matters: a stable spec that accurately describes a stable reality is fine; an installed spec that no longer describes reality is misleading. The spec owner should ask: *does this spec still accurately describe how this part of the org works? If not, update it or close the scope.*

**Who acts:** each spec's declared owner.

---

### Adopter extension points

The reading guide is standard-level but adopter-extensible. Adopters may:
- Override the action guidance for specific metrics in their extension spec
- Add org-specific decision protocols (e.g. "when inbox-load turns red, flag in the weekly leadership review")
- Name specific roles (e.g. "the governance owner is the VP Engineering") rather than the generic "governance owner"
- Adjust which metric families appear in the report (suppress metrics for capabilities not yet active)

Removing a metric family's interpretation is not permitted — the reading guide is a floor, not a ceiling.

## Acceptance scenarios

### Reader understands what a red ownership score means without asking

Given a Governance Pulse report with one scope showing no named lead
When a stakeholder reads the ownership section
Then the reading guide tells them: this scope is ungoverned, the right question is whether it needs an owner or should be stopped, and who should act

### Adopter customises action guidance for their org

Given an adopter whose extension spec adds "when inbox-load turns red, flag in the monthly ELT review"
When the Governance Pulse report is generated
Then the generated report incorporates the adopter's specific action protocol alongside the standard interpretation

### Falling contribution is correctly interpreted as maturity, not neglect

Given a project that launched 6 months ago with high contribution and now shows low contribution
When the governance owner reads the contribution trend section
Then the reading guide distinguishes the maturity arc from neglect, and prompts the right diagnostic question

### Installed spec is surfaced and diagnosed

Given a spec that has not been edited in 180 days but the scope it describes has changed
When the spec activity section is read
Then the reading guide frames the question: is this stable or installed? The spec owner is named as the person to act.

## Related

- `specs/observability/stakeholder-report/spec.md` — the spec this proposal updates
- `specs/observability/spec.md` — the parent observability capability
- `specs/observability/owner-health/spec.md` — source of ownership metrics
- `specs/observability/decision-health/spec.md` — source of decision velocity metrics
- `specs/observability/inbox-health/spec.md` — source of inbox responsiveness metrics
- `specs/observability/contributor-activity/spec.md` — source of contribution trend metrics
- `specs/observability/spec-activity/spec.md` — source of spec activity metrics
