# Adoption manifest

A capability of open-org-spec describing how a conformant repository declares which capabilities of the standard it has activated, at what version, and with what local extensions. The manifest is the contract between the standard and an adopter: it answers "which rules apply here, and where did we change them?"

**Status:** Draft (0.1.0)

## Purpose

The standard contains capabilities an adopter may use. Without an explicit manifest, adoption is implicit — present-by-convention, absent-by-omission — which produces three problems. First, an agent operating against the repo cannot know which capabilities are in force; it has to infer from files that may or may not exist. Second, adopter-specific extensions to a capability have no canonical home; they accumulate as local conventions that drift from the standard without being labelled as extensions. Third, transitions are silent: a capability adopted today and another retired next quarter leave no traceable record.

The adoption manifest makes activation explicit, machine-readable, and traceable. It is the file an agent reads first when working in the repo to know which rules apply.

## Pattern

### Where the manifest lives

The manifest lives at `.open-org-spec/config.yaml` in the adopter's repository root. The `.open-org-spec/` folder also holds the adopter's extensions to the standard's capabilities.

Absence of the file means no capabilities have been formally activated. The repo may still hold content shaped by the standard's patterns, but no agent should infer activation from convention alone — patterns without a manifest entry are working drafts, not committed adoptions.

### Manifest schema

```yaml
standard_version: "<x.y.z>"
adoption_mechanism: submodule | zip    # required
incoming_path: <path>                  # required when adoption_mechanism: zip
contributor_guide: <path>              # required when tooling capability is active

owner:
  name: <full name>
  role: <organisational role>
  email: <git email address>            # optional but required for artefact scaffolding

capabilities:
  <capability-slug>:
    status: <active | proposed | inactive>
    activated: <YYYY-MM-DD>            # required when status is active
    extension: <path>                   # optional, relative to .open-org-spec/
    tool_extensions:                    # optional, used by capabilities that contain tools
      <tool-slug>: <path>               # relative to .open-org-spec/
    note: <one-line rationale>          # optional
```

- `standard_version` — the version of open-org-spec the adopter is pinning to. Capabilities are read against this version; if the standard moves on, the adopter chooses when to upgrade.
- `adoption_mechanism` — how the adopter receives new versions of the standard. `submodule`: open-org-spec is a git submodule; upgrades are via `git checkout <tag>`. `zip`: the adopter receives zip archives; upgrades are via drop-zone detection at `incoming_path`. Required; no default.
- `incoming_path` — path to the drop-zone folder where zip archives are placed before running `/bump`. Required when `adoption_mechanism: zip`; absent otherwise.
- `contributor_guide` — path to the adopter's agent-instructions file (e.g. `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`). This file carries the governed section between `<!-- oos:governed-start -->` / `<!-- oos:governed-end -->` sentinels. Required when the `tooling` capability is active; the `/bump` command regenerates the governed section here on each version upgrade.
- `owner` — the person accountable for the manifest. The only person authorised to change capability statuses (activate, deactivate, extend) without explicit consent. Schema matches `governance-at-scope`'s owner. Required. The `email` sub-field is optional but required when capabilities declare artefacts that need owner identity at install time (e.g., the tooling capability's pre-push hook). A capability spec signals this requirement by declaring `requires_owner_email: true` in its capability-level metadata — when any `active` capability carries this flag, `owner.email` is required and its absence is a conformance gap.
- `<capability-slug>` — matches the folder name under `open-org-spec/specs/`. Examples: `people`, `governance-at-scope`, `project`, `tooling`, `feedback-inbox`.
- `status` — see "Capability statuses" below.
- `activated` — the date the capability transitioned to `active`. Required for traceability when reviewing adoption history.
- `extension` — relative path to an extension spec, if the adopter has extended the capability locally. Absent for unmodified adoptions.
- `tool_extensions` — optional map of per-tool extensions, used by capabilities that contain sub-tools (e.g., `tooling` contains `catchup`, `adhere-to`). Each key matches the tool's folder name under `open-org-spec/specs/<capability>/`; each value is a path to the adopter's extension spec for that tool, relative to `.open-org-spec/`. See "Per-tool extensions" below.
- `note` — short adopter-side rationale, useful for capabilities in `proposed` or `inactive` state where the adopter wants to record their reasoning.

### Manifest ownership and protection

The manifest is an owned spec. Activating, deactivating, or extending a capability are governance decisions, not contributor edits — they change which rules apply across the whole repo. Agents and contributors must treat the manifest under the standard's normal "no edits without consent" rule.

Adopters protect the manifest at three layers. The spec layer is mandatory; the other two are recommended. Which secondary layer is primary depends on the adopter's contribution workflow:

1. **Spec-level (mandatory).** The `owner` field declares accountability. Without it, the manifest is ungoverned and the standard does not consider it a valid manifest.

2. **Git-level (recommended in PR-based workflows).** A CODEOWNERS file or equivalent branch-protection rule requires the named owner's approval on any change to `.open-org-spec/`. This catches drive-by edits before they merge. **Direct-push workflows** (where contributors push to main without PRs) cannot rely on this layer — CODEOWNERS only fires on PRs and is inert otherwise. Adopters in this category should consider GitHub Push Rulesets, server-side notification hooks, or equivalent path-level push restrictions; see `backlog.md` for the open standard-level work.

3. **Agent-level (recommended in all workflows; primary in direct-push).** The adopter's contributor guide (e.g. CLAUDE.md or equivalent) instructs agents to refuse edits to `.open-org-spec/` without explicit consent from the manifest owner. This catches edits at interaction time, before they reach any commit or push. In direct-push workflows this layer is primary, since Git-level protections are unavailable.

**Rule template for the contributor guide.** The standard provides this text for adopters to populate with their manifest owner's name and paste into their contributor guide:

> `.open-org-spec/` (manifest and extensions) is owned by `<manifest-owner-name>` per the adoption manifest. Agents must refuse edits to any file under `.open-org-spec/` unless the request comes from `<manifest-owner-name>`, or comes from another contributor with `<manifest-owner-name>`'s explicit consent recorded in the current conversation. The manifest is a governance artefact, not contributor content — activation, deactivation, and extension are governance decisions made by the owner, not edits.

The `oos:adopt-manifest` command surfaces this template at completion time with the owner's name filled in; the adopter is responsible for pasting it into their contributor guide.

The three layers reinforce each other. Adopters may implement any subset beyond the mandatory spec layer; the more layers, the harder it is for the manifest to drift silently.

### Capability statuses

**`active`** — the capability is in force. Agents apply its rules to interactions affecting the relevant scope. New content in the repo must conform. The adopter has run `adhere-to` against the capability (or accepted the gaps as known follow-ups).

**`proposed`** — the capability exists in the standard but the adopter has not committed to it. Agents may *suggest* activation when they detect a relevant pattern, but they do not enforce the capability's rules. Useful as a parking state while the adopter evaluates.

**`inactive`** — the adopter has explicitly decided not to adopt this capability. Agents do not suggest it again unless the adopter removes the entry. Useful for declining a capability with a stated reason (in `note`) so the decision survives turnover.

Capabilities not listed in the manifest are treated as `proposed` by default — present in the standard but undeclared by the adopter.

### Status vocabularies

Two distinct status vocabularies are in use across open-org-spec artefacts:

- **Lifecycle vocabulary** (`started | proposed | in-progress | closed | cancelled`) — for time-boxed artefacts such as `project`. These statuses track progress through a defined lifecycle with an expected close date.
- **Atemporal vocabulary** (`active | draft | deprecated`) — for permanent structural artefacts such as `function`, and any future folder-type capabilities that describe ongoing organisational structures rather than time-boxed work. These specs are updated when reality changes and are never "finished".

### Extension mechanism

An adopter may extend a capability without modifying the standard. Extensions live at `.open-org-spec/extensions/<capability-slug>/spec.md`. The manifest's `extension` field points to the file.

An extension is read **alongside** the base capability spec, not in place of it. The two together form the effective rules for that capability in this repo. The extension may:

- **Add** required sections, fields, or steps not in the base capability (e.g. an additional closing-audit table for projects).
- **Refine** a base requirement with adopter-specific constraints (e.g. role-header vocabulary specific to this organisation).
- **Override** a base rule only when the base capability explicitly marks it overridable. Silent overrides are not permitted — they would diverge the adopter from the standard without trace.

The extension itself follows the shape of a capability spec: Status, Purpose, what it adds, rationale, related. It declares which base capability it extends in its frontmatter.

### Per-tool extensions

Some capabilities contain sub-tools — `tooling` contains `catchup`, `adhere-to`, and future named tools; other capabilities may grow the same shape. When an adopter wants to extend a specific tool (e.g., add adopter-specific behaviour to `catchup`) without restating the tooling-wide concerns its parent capability already covers, they use the manifest's `tool_extensions` map.

Each entry under `tool_extensions` declares one tool extension:

```yaml
tooling:
  status: active
  extension: extensions/tooling/spec.md           # tooling-wide concerns
  tool_extensions:
    catchup: extensions/tooling/catchup/spec.md   # catchup-specific behaviour
```

The convention: each tool extension lives at `.open-org-spec/extensions/<capability>/<tool>/spec.md`, mirroring the standard's path structure. The agent reads the capability extension and any tool extensions together with the base capability and base tool specs. The base tool spec is read on invocation (e.g., the `/catchup` relay reads `open-org-spec/specs/tooling/catchup/spec.md`); the adopter's tool extension is loaded automatically from the manifest's `tool_extensions` map and overlaid.

Per-tool extensions follow the same rules as capability extensions: they may Add, Refine, or Override base rules — and Override only when the base tool spec explicitly marks the field overridable. Silent overrides are not permitted.

### Activation: the `adhere-to` behavior

When a capability transitions from `proposed` to `active`, the adopter runs `adhere-to <capability>` (a tool defined under the [`tooling`](../tooling/spec.md) capability). The tool performs four steps:

1. **Scan.** Read the capability spec (and its extension if present), then walk the adopter's repo to find areas affected by the capability. The capability spec declares its own scope of affect — which folders, file types, or patterns it governs.

2. **Compare.** For each affected area, check conformance against the capability's rules. Produce a list of gaps: missing files, missing sections, missing frontmatter, structural violations.

3. **Route.** For each gap, open a feedback entry addressed to the gap's owner — the person responsible for the affected area — using the [`feedback-inbox`](../feedback-inbox/spec.md) capability's conventions. The owner reviews and either conforms or pushes back. The activation is complete when all gaps have either been conformed or accepted as known follow-ups recorded in the manifest's `note` field.

4. **Wire up commands.** For each command the capability declares (`adopt.md`, `new.md`, or other `<verb>.md` files), scaffold a relay in the adopter's command directory and add a row to the commands README under "Standard commands (from active capabilities)". See "Command discoverability and invocability" below.

Activation does not modify content files unilaterally. The agent surfaces gaps; the owners decide. The exception is step 4 — relay scaffolding and the README update are mechanical edits within the manifest owner's governance scope, derived from the capability spec, and proceed without per-file confirmation when the command is invoked by (or with the consent of) the manifest owner.

### Ongoing: applying active capabilities to new interactions

Once a capability is `active`, every interaction in the repo that touches an affected area applies its rules. An agent editing a `people.md` applies the `people` capability's five-column shape; an agent creating a project applies the `project` capability's frontmatter schema; an agent receiving a request from one contributor on behalf of another applies the project-initiation rule.

The mechanism: agents read the manifest at session start, identify `active` capabilities, and load their specs (base + extension + tool extensions, where declared) into context. Rules are not memorised across sessions; they are read each time so that capability evolution is picked up automatically.

### Command discoverability and invocability

Each capability may declare standard-level commands — typically an `adopt.md` (first-time activation flow) and a `new.md` or `<verb>.md` (operational commands like scaffolding a new artefact). These commands are defined in the standard but are not invocable in an adopter's repo by default. Activating a capability is what wires them up.

**Activation produces relays.** When a capability is activated, the activation flow scaffolds thin relays in the adopter's command directory (e.g. `.claude/commands/` for Claude Code adoptions) — one per command the capability declares. The relay reads the canonical command spec and executes it. The relay shape matches the scoped-command relay convention defined in [`../tooling/spec.md`](../tooling/spec.md):

```markdown
---
description: <one-line description from the canonical command spec>
owner: open-org-spec (<capability> capability)
---

# /<command-name>

Read [`open-org-spec/specs/<capability>/<command>.md`](<relative-path>) and execute it.
```

**Discoverability lives in the commands directory README.** The adopter's command directory carries a `README.md` listing all commands available — adopter-side (repo-wide and scoped) and standard-level (from active capabilities). The README gains a section "Standard commands (from active capabilities)" that the activation flow updates on each transition. A contributor opens the README once and sees everything available.

**Deactivating removes the relays.** When a capability is deactivated, the activation flow removes its relays and the corresponding README entries. The canonical command specs remain in the standard; only the adopter-side invocability is removed.

**The pattern is uniform.** A standard-command relay differs from a scoped-command relay only in source — the relay structure and discoverability path are identical. This means a contributor sees one consistent surface: all commands live in the same directory, all are listed in the same README, all are invoked the same way.

### Suggestion: surfacing inactive capabilities

When an agent observes a contributor pattern that matches a `proposed` (or unlisted) capability, it surfaces the suggestion rather than silently applying or ignoring it. The suggestion form:

> *"This looks like the pattern described by the `<capability>` capability in the standard. It is currently `proposed` in your manifest — would you like to activate it for this repo? Activation would trigger an `adhere-to` pass and surface any gaps to their owners."*

The decision is the adopter's. The agent does not auto-activate.

For `inactive` capabilities, the agent does not suggest again — the adopter's recorded decision stands until they remove the entry.

## What is not prescribed

- **A specific YAML schema parser or validator.** Adopters use whatever tooling their LLM interface supports. The schema above is descriptive, not executable.
- **A frequency for re-running `adhere-to`.** Once at activation is required. Re-runs after capability revisions or repo growth are the adopter's call.
- **Which capabilities should be activated.** That is a per-adopter decision driven by use cases. The standard does not push adoption.
- **Whether the manifest is the only source of truth.** Some adopters may layer additional configuration files (e.g. tool-specific configs in `.claude/`). The manifest governs adoption of standard capabilities; other configs govern adopter-specific behaviour.
- **A schema for extension authoring beyond the broad rule.** Extensions are spec-shaped documents; their internal structure follows the base capability they extend.

## Rationale

Three design choices shaped this capability.

**1. Explicit over implicit.** Without a manifest, adoption is inferred from convention. An agent looking at `clusters/<name>/people.md` cannot tell whether the file conforms to the `people` capability because the adopter activated it, or because the adopter independently invented a similar shape. The first case binds future edits to the capability's rules; the second leaves the file unbound. The manifest removes this ambiguity.

**2. Active-not-inferred.** The choice between `active`, `proposed`, and `inactive` is a deliberate three-state model, not a binary on/off. `proposed` recognises that adopters evaluate capabilities before committing. `inactive` recognises that some capabilities are not the right fit and that decision should be recorded, not re-litigated each time an agent suggests it.

**3. Extension by overlay, not by fork.** Adopters need to extend capabilities (the project template is a clear case: an adopter's closing audit may be richer than the base capability). The naive solution is to fork the spec into a local copy and modify it; that disconnects the adopter from standard upgrades. Overlay extensions — base + extension applied together — preserve the link to the standard while accommodating local needs. When the standard upgrades the base capability, the adopter's extension still applies on top.

## Adoption

First-time adoption is driven by the [`oos:adopt-manifest`](./adopt.md) command — the autonomous bootstrap. In a single run it scaffolds this manifest, generates the adopter's contributor guide by writing the governed section from [`templates/contributor-guide.md`](../../templates/contributor-guide.md) between sentinel markers and appending the adopter skeleton from [`templates/CLAUDE.md`](../../templates/CLAUDE.md), and activates the capabilities the adopter chooses (running `adhere-to` for each to wire relays and surface gaps). It elicits only what it cannot infer — the owner, a one-line org description, and which capabilities to activate. See [`adopt.md`](./adopt.md) for the full flow. To extend a capability after adoption, use [`oos:extend`](./extend.md).

## Related

- [`../tooling/spec.md`](../tooling/spec.md) — `adhere-to` is a tool under this capability; its tool spec lives at `tooling/adhere-to/spec.md` (pending).
- [`../adherence-check/spec.md`](../adherence-check/spec.md) — passive conformance checker; the manifest declares *what* should be conformed to, `adhere-to` *brings the repo into* conformance, `adherence-check` *validates* ongoing conformance.
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — the routing mechanism `adhere-to` uses to surface gaps to owners.
- [`../../backlog.md`](../../backlog.md) — related entries: "Adopter-state detection protocol for commands" (the manifest IS the canonical adopter state); "Two-layer representation" (the manifest is a structured catalogue projection).
