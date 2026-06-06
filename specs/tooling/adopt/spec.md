# Adopt capability (command)

Invoked as: `/adopt` (no argument) or `/adopt <capability-slug>`
Part of: [`tooling`](../spec.md) capability.

## Purpose

Activate a capability in an existing open-org-spec adoption — guided, in a single run, with no manual file editing. Given a capability slug, the command reads the capability spec, scaffolds the required extension wiring, updates the manifest, wires command relays, and verifies conformance via `adhere-to`.

Invoked **without a slug**, the command acts as a capability discovery guide: it reads the manifest and the standard's capability index and shows the adopter exactly what is active, what is proposed but not yet active, and what exists in the standard but is not yet declared — so the adopter can choose what to activate next.

This is the per-capability counterpart to [`oos:adopt-manifest`](../../adoption-manifest/adopt.md), which bootstraps a new adoption from scratch. `/adopt` is for adopters who already have a manifest and want to activate an additional capability.

The alternative without this command is: read the capability spec, manually create the extension wiring file, manually edit `config.yaml`, manually wire command relays, and run `adhere-to` to check. `/adopt` does all of that, in order, and surfaces gaps before the adopter commits.

## No-argument mode (discovery)

When invoked without a capability slug, the command reads `.open-org-spec/config.yaml` and `open-org-spec/specs/` and renders a capability map:

```
Capability status — <adopter name>

Active (rules apply now):
  ✓ governance-at-scope   Who decides at each scope
  ✓ feedback-inbox        Open feedback inbox convention
  ✓ people                People rosters at scope
  ✓ tooling               Commands, agents, hooks
  ✓ observability         Repo health indexes
  ✓ spec-health           Conformance + catalogue agents
  ... (all active)

Proposed (declared, not yet active):
  ○ capability-lifecycle  Formal capability change workflow
  ○ adherence-check       Passive conformance validation

Available in standard (not yet declared):
  · federation            Multi-adoption orchestration
  · contributor-registry  Contributor discovery and registry
  · ... (any spec in open-org-spec/specs/ not in manifest)

To activate a capability: /adopt <capability-slug>
To check conformance on an active capability: /adhere-to <capability-slug>
```

**Sorting:** active first (alphabetical), then proposed (alphabetical), then available (alphabetical). Dependencies are noted inline — if an available capability requires another that is not active, flag it: `(requires: <dep>)`.

## Preconditions

- `.open-org-spec/config.yaml` exists (refuse if not — redirect to `oos:adopt-manifest`).
- When a slug is given: the named capability exists in `open-org-spec/specs/<capability-slug>/spec.md` (refuse if not found).
- When a slug is given: the capability is not already `status: active` in the manifest (refuse and redirect to `/adhere-to <capability>` if it is).
- When a slug is given: the running contributor is the manifest owner declared in `config.yaml` (refuse if not — capability activation is a manifest-owner act).

## Steps

### Step 1 — Read the capability spec

Read `open-org-spec/specs/<capability-slug>/spec.md` in full. Extract:

- **Extension points** — any `## Extension points` section listing adopter-declared values (e.g. escalation threshold, scope tree, output paths). These become the fields the adopter must fill in the wiring file.
- **Dependencies** — any `## Dependencies` section listing other capabilities that must be active first. Check each against the manifest; if any dependency is not `status: active`, surface a blocking gap and stop.
- **Commands shipped** — any `*.md` files sibling to `spec.md` in `open-org-spec/specs/<capability-slug>/` (e.g. `new.md`, `scan.md`, `registry.md`). These become command relays.
- **Artefacts** — any `## Artefacts` block (YAML fenced), which `adhere-to` uses in Step 5.

### Step 2 — Scaffold the extension wiring file

Create `.open-org-spec/extensions/<capability-slug>/spec.md` if it does not already exist.

The file should follow this shape:

```markdown
# <Capability display name> — <Adopter name> wiring

Adopter-side extension for the `<capability-slug>` capability.
Fills in the extension points declared in `open-org-spec/specs/<capability-slug>/spec.md`.

**Extends:** `open-org-spec/specs/<capability-slug>/spec.md`
**Owner:** <manifest owner name>
**Declared in:** `../../config.yaml` under `capabilities.<capability-slug>`

## Extension points

<For each extension point found in Step 1, emit a field entry:>

| Extension point | Value |
|---|---|
| <extension point name> | `[fill in]` |
```

For extension points that have a standard-declared default (e.g. `R-` prefix for risk IDs, `30 days` for escalation threshold), pre-populate the default rather than `[fill in]`. Note it is a default so the adopter knows they can override it.

If the capability has no extension points, write the file with a one-line note: `No extension points — this capability is fully prescribed by the standard.`

If the file already exists, do not overwrite it. Note its presence and proceed.

### Step 3 — Update config.yaml

Add or update the capability entry in `.open-org-spec/config.yaml`:

```yaml
<capability-slug>:
  status: active
  activated: <today ISO date YYYY-MM-DD>
  extension: extensions/<capability-slug>/spec.md
  note: "Activated via /adopt <capability-slug>."
```

If the capability has no extension file (Step 2 found no extension points and nothing was scaffolded), omit the `extension` field.

If the capability entry already exists with `status: proposed`, update only `status`, add `activated`, and add the `extension` field. Preserve any existing `note`.

### Step 4 — Wire command relays

For each command file found in Step 1 (sibling `*.md` files to `spec.md`, excluding `spec.md` itself):

1. Determine the relay name from the file name (e.g. `new.md` → `/new-<capability-slug>`, or the command name declared in the file's opening line if it overrides the default).
2. Check whether a relay already exists in the adopter's command directory (e.g. `.claude/commands/<relay-name>.md` for Claude Code). If it does, skip.
3. Create the relay file at the adopter's command directory:

```markdown
---
description: <first-line description from the canonical command file>
canonical_spec: open-org-spec/specs/<capability-slug>/<command-file>.md
canonical_spec_version: "<current standard_version from config.yaml>"
---

# /<relay-name>

Read [`open-org-spec/specs/<capability-slug>/<command-file>.md`](../../open-org-spec/specs/<capability-slug>/<command-file>.md) and execute it.
```

4. Add a row to the adopter's commands README under "Standard commands (from active capabilities)":

```
| `/<relay-name>` | <one-line description> | `open-org-spec/specs/<capability-slug>/<command-file>.md` |
```

### Step 5 — Run adhere-to

Invoke `/adhere-to <capability-slug>`. This verifies conformance, scaffolds any artefacts declared in the capability spec's `## Artefacts` block, and surfaces remaining gaps.

Do not proceed past Step 5 if `adhere-to` reports a blocking dependency gap (a required capability that is not active). Surface the dependency and stop — the adopter must activate it first.

### Step 6 — Surface summary

Report to the adopter:

```
/adopt <capability-slug> — complete

Manifest:        .open-org-spec/config.yaml updated — <capability-slug>: active
Extension:       .open-org-spec/extensions/<capability-slug>/spec.md
Commands wired:  <list of relay names, or "none">
adhere-to:       <N gaps surfaced / "all conformant">

Fill-in required:
  <list of [fill in] placeholders remaining in the extension wiring file, with their names>

Next steps:
  1. Fill in the extension wiring file placeholders above.
  2. Review and resolve any adhere-to gaps in the feedback inboxes.
  3. Commit the changes (extension file, manifest, command relays).
```

## Refusal conditions

- **Manifest does not exist.** Redirect to `oos:adopt-manifest`.
- **Capability not found.** `open-org-spec/specs/<capability-slug>/spec.md` does not exist. List available capabilities and stop.
- **Already active.** The capability is already `status: active`. Redirect to `/adhere-to <capability-slug>` for a conformance recheck.
- **Not the manifest owner.** Capability activation is a manifest-owner act. The command refuses for any other contributor and surfaces an explanation.
- **Unmet dependency.** A required dependency capability is not `status: active`. Name the blocking dependency and stop. Do not partially activate.

## Non-goals

- **Does not invent adopter content.** Extension point values marked `[fill in]` are placeholders; the adopter fills them in after the command runs.
- **Does not create scope-level artefacts** (e.g. `risks/` folders at cluster level). Those are created by the contributors working in those scopes, once the capability is active. `/adopt` activates the capability at the manifest level; `/adhere-to` surfaces where scope-level artefacts are missing.
- **Does not push or commit.** All writes are to the working tree. The adopter reviews and commits via their normal save flow (e.g. `/update`).
- **Does not update an already-active capability.** For re-wiring or schema changes after a standard version bump, use `/adhere-to <capability>`.

## Related

- [`../../adoption-manifest/adopt.md`](../../adoption-manifest/adopt.md) — bootstraps a new adoption; calls `/adopt` for each initially chosen capability.
- [`../adhere-to/spec.md`](../adhere-to/spec.md) — invoked in Step 5; the conformance verifier.
- [`../spec.md`](../spec.md) — the tooling capability this command belongs to.
