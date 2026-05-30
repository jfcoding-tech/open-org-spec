# Adherence check

A capability of open-org-spec that reports how well content conforms to a named capability's schema. Targets a `governance-at-scope` scope or a `project` instance at v0; read-only.

**Status:** Draft (0.1.0)

## Purpose

Capabilities declare conformance requirements — `governance-at-scope` for governance folders, frontmatter, scope discipline, contradictions; `project` for required fields, the [transition gate](../project/spec.md#transition-gate), closing-audit completeness. Without a mechanism to check these, gaps accumulate silently — adopters can believe they conform while drifting from the schema. `adherence-check` is that mechanism, run against a named capability + target.

## Pattern

### Invocation

The check runs against a named **target capability + target**:

- `governance-at-scope` + a scope path (the repository root, a module path, a cross-module workstream path). Context: the scope's governance hierarchy, walked from target upward.
- `project` + a project slug or path (e.g., `sales-ops-agent-poc`). Context: the project's `spec.md` and any extension declared in the adoption manifest.

### Output: a report of findings

The check produces a **report** with zero or more **findings**. Each finding has:

- **Rule** — the specific conformance requirement cited, referenced to a section in `governance-at-scope/spec.md` by path + anchor.
- **Target** — the scope path and (where applicable) the specific field, key, or line in question.
- **Observation** — what was expected vs. what was found, one line.
- **Severity** — `violation` (breaks a required rule), `gap` (required content missing), `warning` (detected but potentially ambiguous).
- **Auto-fix available** — `false` at v0.

A report with zero findings indicates conformance within the limits of the check.

### Findings are machine-readable

The canonical report shape is YAML:

```yaml
findings:
  - rule: <path#anchor into governance-at-scope/spec.md>
    target: <scope-path[: field-name]>
    observation: <expected vs found>
    severity: violation | gap | warning
    auto_fix_available: false
```

A prose rendering of the same report is acceptable for human consumption; the YAML shape is the contract.

### Checks performed

#### Against `governance-at-scope`

- **Governance folder presence.** If the scope has content that would normally be governed (operational specs, decisions) but no `governance/` folder, emit a `warning` — absence may be valid (the scope inherits from a higher scope) or an oversight.
- **Required frontmatter fields.** For each `governance/README.md` found, validate: `scope`, `applies_to`, `owner` (with `name` and `role`), `daci` (with at least `driver` and `approver`), `cross_references`. Missing fields emit a `gap` finding citing the rule in `governance-at-scope/spec.md`.
- **Cross-reference integrity.** Each path in `cross_references` must resolve to an existing `governance/` folder. Broken references emit `violation` findings.
- **Sibling `decisions/` folder.** If `governance/` exists at a scope, check for a peer `decisions/` folder. Its absence emits a `gap` finding.
- **Scope discipline — role-name sweep.** For each DACI entry at the target, compare role names against DACI entries at higher scopes. An exact role-name match at both scopes, without a documented exception, emits a `warning` — the adopter should confirm the participant carries accountability at both scopes explicitly.
- **Best-effort contradiction detection.** Walk the governance hierarchy pairwise and compare frontmatter-level rules between adjacent scopes. Direct field-value conflicts emit a `violation` finding flagging both rules by path.

#### Against `project`

The check validates conformance to the `project` capability's schema, its [Gate A content gate](../project/spec.md#gate-a--started--proposed-content-gate), and its [tooling stamps](../project/spec.md#tooling-stamps). Per the capability's extension mechanism, an adopter's manifest may declare additional required fields; those fields participate in the checks below alongside base requirements.

- **Status value valid.** `status` is one of `started | proposed | in-progress | closed | cancelled` (plus any adopter extension's variant — e.g., an adopter may use `active` for `in-progress`). Other values emit a `violation`.
- **Required frontmatter fields populated.** `project`, `status`, `opened`, and `owner` (with `name` and `role`) are present and not `TBD`. Missing or `TBD` values emit a `gap` citing Gate A. `status: started` is exempt from the `TBD` check on content fields (drafts are expected to be incomplete); other statuses are not.
- **Required prose sections populated.** Objective and Close criterion are present and non-empty. Missing sections or `TBD` values emit a `gap` — *except* when `status: started`, in which case `TBD` in Close criterion emits a `warning` (it's a known incomplete-draft signal, not a violation).
- **Hypothesis when experimental.** If the project declares itself experimental (in prose or via an extension-declared marker such as `Type: experiment`), the Hypothesis section is populated. Missing emits a `gap`.
- **Success metrics declared or excused.** Either the Success metrics section is populated, or the spec carries the explicit line *"Success metrics: not applicable — <rationale>"*. Silent omission emits a `gap`.
- **Gate A honoured.** When `status: proposed` or later (`in-progress`, `closed`), every check above must pass with no `TBD`s. Failures at these statuses emit a `violation` rather than a `gap` — the project transitioned to `proposed` (or beyond) without meeting Gate A.
- **Gate B audit trail present.** When `status: in-progress`, the spec records the approval event auditably (an inline approval note, a feedback entry pointer, or both — see [Gate B](../project/spec.md#gate-b--proposed--in-progress-approval-gate)). Absence emits a `gap`. Self-approval is acceptable as long as it is explicitly recorded.
- **Extension-declared fields present.** When the adopter's manifest declares additional required fields, validate their presence. Missing fields emit a `gap` citing the extension.
- **Tooling stamp present.** The `tooling` frontmatter block exists. Missing block emits a `gap`. Empty block (`tooling: {}`) emits a `warning` only when the project's `opened` date is before 2026-05-27; otherwise it emits a `gap` (a project opened after that date should have at least `oos:new project` stamped).
- **Tooling stamps reflect actual tool use.** If git history (or any other observable signal) shows a known state-changing tool ran against the file but the stamp is absent, emit a `warning` — the file was modified by a tool that should have stamped, but did not.

The check does **not** validate whether the named owner is the requester — that is human judgement per the capability's [Project initiation](../project/spec.md#project-initiation) rule and is outside v0 scope. A reviewer reading the report carries that question alongside the mechanical findings.

## What adherence-check is not

- **A fix tool.** It reports; it does not mutate. Fixes are authored through the [`capability-lifecycle`](../capability-lifecycle/spec.md) workflow.
- **A judgement tool.** It does not decide whether an owner is genuinely accountable vs. a stakeholder, whether a DACI assignment is appropriate, or whether a contradiction should be resolved up or down. Human judgement remains with the owner.
- **A completeness gate.** Conformance to the schema does not imply governance is well-designed, sufficient, or healthy — only that it follows the standard's required form.

## Not prescribed (v0)

- **Accountability semantics.** Whether an owner is stakeholder vs. accountable is human judgement; the check validates field presence only.
- **Prose-body rule comparison.** Contradiction detection across prose bodies requires semantic comparison; v0 flags only frontmatter-level conflicts.
- **Cross-repository checks.** The check operates within one repository; references to external systems are not followed.
- **Auto-fix proposals.** v0 surfaces findings; a future capability may propose concrete fixes.
- **Scheduling.** Whether the check runs in CI, on a schedule, or on-demand is an adopter choice.

## Rationale

Three things change when adherence is mechanical:

1. **Gaps become visible.** An adopter can see what they have and what they're missing without re-reading the schema each time.
2. **Drift becomes catchable.** A check run on a schedule or in CI catches when conformance slips.
3. **Contributions self-validate.** A contributor editing a governance folder can run the check before committing and see whether their edit broke conformance.

None of this replaces human review. It makes the mechanical part mechanical, leaving judgement to humans.

## Invocation

See [`check.md`](./check.md) for the command file.

## Related

- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — the schema this check validates against.
- [`../project/spec.md`](../project/spec.md) — the second capability this check validates against. The transition gate referenced from the project checks above lives there.
- [`../capability-lifecycle/spec.md`](../capability-lifecycle/spec.md) — the workflow through which changes to this capability are proposed.
- [`../../backlog.md`](../../backlog.md) — the *two-layer catalogue* entry, which if adopted would provide a cheap data source for this check.
