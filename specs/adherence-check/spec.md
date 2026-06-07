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

#### Against adoption-manifest

- **Manifest file presence.** If any governed content exists (governance folders, project specs, people files, feedback inboxes) but `.open-org-spec/config.yaml` is absent, emit a `warning`.
- **`standard_version` present.** Missing or empty emits a `gap`.
- **`owner.name` and `owner.role` present.** Missing either emits a `gap`.
- **`owner.email` when required.** If any `active` capability in the manifest has `requires_owner_email: true`, and `owner.email` is absent or empty, emit a `gap` citing the artefact-scaffolding requirement.
- **`adoption_mechanism` present and valid.** Must be `submodule` or `zip`. Missing emits a `gap`; any other value emits a `violation`.
- **`incoming_path` present when mechanism is `zip`.** When `adoption_mechanism: zip`, `incoming_path` must be declared. Missing emits a `gap`.
- **`contributor_guide` present when `tooling` is active.** When the `tooling` capability has `status: active`, `contributor_guide` must be declared. Missing emits a `gap`. When declared, the file at that path must exist; a broken path emits a `violation`.
- **`status` valid for each capability entry.** Must be `active`, `proposed`, or `inactive`. Any other value emits a `violation`.
- **`activated` present for active capabilities.** Every `status: active` entry must have `activated` in `YYYY-MM-DD` format. Missing or malformed emits a `gap`.
- **`extension` path resolves.** When declared, must resolve to an existing file relative to `.open-org-spec/`. Broken path emits a `violation`.
- **`tool_extensions` paths resolve.** Each value must resolve to an existing file. Broken paths emit `violation` findings.
- **Unknown capability slug.** Slugs not matching any known capability folder emit a `warning`.

#### Against people

- **Two-table separation.** A single merged table emits a `violation`. A `people.md` with only a lead table (no working group) is conformant.
- **Lead table columns.** Must have `Name`, `Role`, `Authority`. Missing columns emit a `gap`. Entirely absent lead table emits a `gap`.
- **Working group table columns.** When present, must have `Name`, `Job title`, `Affiliation`, `Function`, `Areas in scope`. Missing columns emit a `gap`. Extra columns are silently ignored.
- **Function vocabulary.** Each `Function` cell must be a value from `Owner | Lead | Driver | Approver | Liaison | Contributor | Member` (with optional `(pending acknowledgement)` suffix, or combined with `+` separator — validate each part separately). Out-of-vocabulary values emit a `violation`.
- **`(pending acknowledgement)` on authority functions.** Any row with `Owner`, `Driver`, or `Approver` in `Function` that lacks the `(pending acknowledgement)` suffix emits a `warning` — the marker must be present until the person explicitly acknowledges the assignment.
- **`Last verified` line.** When a working group table is present, the file must contain `**Last verified:** YYYY-MM-DD`. Missing emits a `gap`; malformed date emits a `violation`.
- **Single `Owner` per scope.** At most one `Function: Owner` row (ignoring suffix). Multiple emit a `violation`.

#### Against feedback-inbox

- **Entry heading format.** Level-2 headings (`## …`) that contain a date-like pattern (`YYYY` or a digit sequence resembling a date) must match `## [resolved] YYYY-MM-DD | <author> — <title>` (with optional `→ <addressee>` before `—`). Non-matching date-bearing headings emit a `warning`. Headings without any date pattern are silently ignored (treated as section headers).
- **Addressee marker.** The addressee marker must be `→` (U+2192) or `->` (ASCII). Both are accepted. Any other arrow variant emits a `warning`.
- **Date format.** Dates in headings and one-liner list items must be `YYYY-MM-DD`. Other formats emit a `warning`.
- **File-level owner declared.** When a `feedback.md` has no per-entry `→` markers, the file must carry a preamble or header naming the owner. Absence emits a `gap`.
- **Resolution marker.** An entry heading without `[resolved]` whose body contains a dated response inline emits a `warning` — appears closed but not marked.

#### Against observability

- **Extension file present.** When `observability` is `active`, the `extension:` path must resolve. Missing emits a `gap`.
- **Extension declares required fields.** Output base path, role-header set, scope tree must be declared. Missing any emits a `gap`. Missing threshold values emit a `warning`.
- **`tool_extensions` paths resolve.** Broken paths emit `violation`.
- **Relay presence per adopted tool.** For each `tool_extensions` entry, a relay must exist in `.claude/commands/`. Missing emits a `gap`.
- **Generation header on output files.** Output files at the declared path lacking the generation header `Generated by /<tool-name> on YYYY-MM-DD` emit a `warning`.
- **`people` capability active when people-resolution enabled.** If the extension enables people resolution but `people` is not `active` in the manifest, emit a `warning`.

#### Against capability-lifecycle

*This check only runs when `capability-lifecycle` is declared `active` in the adoption manifest.*

- **`proposal.md` frontmatter fields.** `change`, `status`, `opened`, `mode`, `owner.name`, `owner.role` required. Missing fields emit a `gap`.
- **`change` matches folder name.** Mismatch emits a `violation`.
- **`status` valid.** Must be `proposed`, `applied`, or `cancelled`. Other values emit a `violation`.
- **`mode` valid.** Must be `develop` or `adopt`. Other values emit a `violation`.
- **`opened` date.** Must be `YYYY-MM-DD`. Malformed emits a `violation`.
- **`problem.md` present.** Absence alongside an existing `proposal.md` emits a `gap`.
- **Acceptance scenario present.** Read the `proposal.md` body. Using LLM semantic judgment, determine whether it contains at least one acceptance scenario (a description of conditions under which the change succeeds, equivalent to Given/When/Then intent even if not using those words). If none is found, emit a `gap`.
- **Delta folders shape.** Subfolders not ending in `-delta` emit a `warning`.
- **Applied proposals have no delta folders.** `status: applied` with remaining `-delta` subfolders emits a `violation`.
- **Archive folder naming.** `archive/` entries must be named `YYYY-MM-DD-<slug>`. Mismatch emits a `warning`. Missing `proposal.md` in archive folder emits a `gap`.
- **Archived proposals closed.** `status: proposed` in archive emits a `violation`.
- **`adopt` mode: no delta targeting `open-org-spec/`.** Emits a `violation`.

#### Against `tooling`

**Contributor guide sentinel check.** Runs when `tooling` is `active` and `contributor_guide` is declared in the manifest.

- **`contributor_guide` file exists.** The file at the path declared in the manifest must exist. Missing emits a `gap` citing the `tooling` capability's contributor-guide section — run `/bump` or create the file from `templates/CLAUDE.md`.
- **Sentinel block present.** The file must contain `<!-- oos:governed-start` followed by a version tag. Missing sentinel emits a `gap` — the governed section has not been written; run `/bump` to regenerate.
- **Sentinel version matches `standard_version`.** The version in `<!-- oos:governed-start v<version> -->` must equal `standard_version` from the manifest. A mismatch emits a `gap` citing the outdated version and instructing the owner to run `/bump` to regenerate the governed section.

**Tooling drift check.** Detects self-contained commands whose embedded logic has diverged from the standard spec they were derived from. It runs when the `open-org-spec` submodule pointer is bumped and is **governance-gated**: only the manifest owner runs it.

**Governance gate.** Read `owner.name` and `owner.email` from `.open-org-spec/config.yaml`. Compare against `git config user.name` and `git config user.email`. If the current contributor is not the declared manifest owner, emit no findings and output: `"Standard drift check is a governance task for <owner name>. No action needed from you."` Stop.

**Discovery.** Scan the adopter's command directory for files containing `canonical_spec` in their frontmatter. Each such file is a self-contained command subject to drift checking. Commands without `canonical_spec` are adopter-authored and not checked.

**Per-command drift check.** For each self-contained command:

1. Read `canonical_spec` (path to the standard spec) and `canonical_spec_version` (the version tag at which the command was last synced).
2. Run `git log <canonical_spec_version>..<current_submodule_tag> -- <canonical_spec_path>` inside the submodule to list commits that touched the canonical spec since the last sync.
3. Classify the highest-severity commit in the range by its conventional commit prefix:
   - `feat!` / `fix!` — **breaking**: execution logic or a security contract changed
   - `feat` / `fix` — **additive**: new capability or bug fix
   - `docs` / `chore` / `refactor` — **editorial**: no behaviour change
4. Emit a finding based on severity:

| Commit severity | Finding type | Meaning |
|---|---|---|
| breaking (`!`) | `violation` | Command must be updated before the submodule bump can land |
| additive | `warning` | Command should be reviewed; may need updating |
| editorial | — | No finding; `canonical_spec_version` is auto-advanced |

5. If no commits touched the canonical spec in the range: no finding; `canonical_spec_version` is auto-advanced to the current submodule tag.

**Auto-advance.** For commands with no drift or only editorial drift, `adhere-to tooling` advances `canonical_spec_version` to the current submodule tag as a mechanical fix. No owner confirmation required.

**Blocking drift.** For commands with `violation` findings, the drift check writes a feedback entry to the manifest owner's governance inbox:

```
## YYYY-MM-DD | adherence-check tooling → <owner> — Drift detected: <command file>

`<command file>` is derived from `<canonical_spec>` (last synced: <canonical_spec_version>).
Breaking changes were introduced between <canonical_spec_version> and <current_tag>:

  <list of breaking commits with their messages>

Review the diff and update the command file before the submodule bump lands.

→ <owner>
```

The submodule bump must not be pushed while `violation` findings remain open. The sentinel file `.open-org-spec/drift-check-pending` (gitignored, local only) blocks the push via a pre-push hook until all violations are resolved and `adhere-to tooling` has cleared the file.

**Sentinel file lifecycle.** The `drift-check-pending` file is created by the submodule bump workflow and contains `from`, `to`, and `bumped_at` fields. `adhere-to tooling` reads it to determine the diff range. When all violations are resolved and all `canonical_spec_version` fields are advanced, `adhere-to tooling` deletes the file. The pre-push hook (owner-gated) blocks until the file is absent.

**Scope.** This check only applies to commands that run in an automated context (scheduled or `--dangerously-skip-permissions`), as defined in [`../tooling/spec.md`](../tooling/spec.md#self-contained-commands). Interactive relays are not self-contained and are not subject to drift checking. The scheduled agents typically in scope are the spec-health `conformance` and `catalogue` agents, the `decision-escalation` governance tool, and the `agent-metrics` weekly value agent — each derived from a standard spec via `canonical_spec`. (The drift check tracks these against their current canonical specs; `agent-metrics` replaces the former observability agent as the value-measurement spec a self-contained command derives from.)

#### Against risk-at-scope

This check only runs when `risk-at-scope` is declared `active` in the adoption manifest.

- **Risk record required fields.** For each `risks/YYYY-MM-DD-*.md` found: validate `id`, `title`, `description`, `owner`, `status`, `escalation_threshold`, `disposition_at`. Missing fields emit a `gap`.
- **`id` format valid.** Must match `R-[0-9]+`. Invalid format emits a `violation`.
- **`status` valid vocabulary.** Must be `open | deferred | mitigated | accepted | closed`. Other values emit a `violation`.
- **`disposition_decision_ref` present for `accepted`.** A risk with `status: accepted` must have `disposition_decision_ref` pointing to an existing decision record. Missing or broken ref emits a `violation` — formal acceptance without a decision record is a governance failure.
- **`disposition_decision_ref` recommended for `deferred`.** A risk with `status: deferred` without `disposition_decision_ref` emits a `warning` — deferral without a rationale record is a weak governance signal.
- **No open risks in closed projects.** If a `risks/*.md` file exists under `projects/closed/`, any risk with `status: open` emits a `violation` — projects must close all risks before archiving.
- **`rag` not manually declared.** The `rag` field is derived; if present in the file it must not contradict the computed value (days open vs `escalation_threshold`). A mismatched `rag` emits a `warning`.
- **Owner declared at scope.** The `owner` field must name a person declared in the scope's `people.md` or governance DACI. Unresolvable owner emits a `warning`.

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
