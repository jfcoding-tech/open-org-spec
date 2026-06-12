# Scope Registry

A capability of open-org-spec describing how an adoption's active scopes are indexed into a machine-readable catalogue — `scopes.yaml` — so that any agent can resolve a scope reference to a feedback inbox with a single file read rather than a filesystem walk.

**Status:** Active

**Owner:** Javier Fernandez

## Purpose

The standard defines structural types — cluster, function, project, module — across multiple capability specs. What it has lacked is a canonical way to reference a *specific instance* of one of those types. An artefact that needs to say "I belong to this specific cluster" or "this risk relates to this specific function" has had no stable identity to point to. Every reference has been either a fragile path string (breaks when folders move) or an implicit inference from file location (breaks when artefacts are cross-cutting or live at the programme level).

**A path string is the wrong reference type.** A risk that declares `scope: clusters/product-development` is coupled to a folder structure that can change. A risk that declares `scope: cluster/product-development` is coupled to a logical identity — the cluster named `product-development` — which survives folder renames, structural reorganisations, and migrations. The type/slug pair is the stable identity; the path is a derived property.

**Routing requires resolving type/slug to a feedback inbox.** Any agent that needs to route to a scope — the risk scanner, the conformance agent, the decision-escalation agent — needs to answer: "given `scope: function/revenue`, what is the feedback inbox?" Without a catalogue, agents either hardcode adopter-specific paths (wrong — not generic) or walk the repo to discover them (slow and token-expensive). The scope registry provides that mapping as a single file read.

**The adoption manifest is not the right home for scope instances.** The manifest declares which capabilities are active — governance policy. Scope instances are operational content: which clusters, functions, and projects exist in this adoption right now. The manifest is a governance artefact owned by one person and not intended as a queryable registry. Separating them keeps the manifest stable and small, while the scope registry evolves as the adoption grows.

**The scope registry is the instance-level complement to the manifest's type-level vocabulary.** The manifest says "the `cluster` structural type is active." The scope registry says "the active clusters are: product-development, customer-acquisition-growth, customer-lifecycle." The two layers together give a complete picture: the types and the instances.

**Validated by a concrete chain of failures.** Programme-level risks were routed to the governance owner because the scanner could not determine which scope's feedback inbox to target. The `risk-scope-field` capability provides the declaration; the scope registry provides the resolution. Both are required to make risk routing correct.

## Vocabulary

**Scope** — any named, independently-governed organisational unit in an adoption. A scope has an owner, carries its own specs and decisions, and exposes a feedback inbox for routing. The four structural types (cluster, function, project, module) and the cross-cutting programme level are all scopes.

**Scope reference** — a stable string in the form `<type>/<slug>` (or `programme` for cross-cutting artefacts) that uniquely identifies a scope instance. The reference is decoupled from the scope's filesystem path — renaming a folder does not change the reference; it changes the `path` field in the catalogue and triggers a `[scope-not-found]` warning for artefacts that have not yet updated to the new slug.

**Scope type** — one of five values from the closed vocabulary below. Types are not open to local extension without a revision to this capability.

**`scopes.yaml`** — the machine-generated catalogue file. Written by the scope registry agent; never edited by hand. The authoritative index of all scopes in the adoption, including closed ones. Lives at the adopter-declared path (default: `governance/catalogue/scopes.yaml`).

**Slug** — the folder name of a scope instance. For most scopes this is the last segment of the scope's path (e.g., `product-development` from `clusters/product-development`). The slug is unique within its type in the catalogue.

## Pattern

### Scope reference format

A scope reference is a two-part string: `<type>/<slug>`. The type comes from the closed vocabulary below; the slug is the folder name of the scope instance.

**Closed type vocabulary:**

| Type | Meaning | Example slug |
|---|---|---|
| `cluster` | A line-of-business unit that owns a user-facing outcome | `product-development` |
| `function` | A cross-cutting organisational function that operates across clusters | `revenue` |
| `project` | A time-boxed initiative with a start, hypothesis, and close criterion | `agentic-coach-phase-3` |
| `module` | A shared-services or infrastructure module that provides capabilities to other units | `ai-factory` |
| `programme` | The repo root — cross-cutting artefacts that belong to no single scope | *(no slug)* |

The `programme` type has no slug. A reference to `programme` means "this artefact belongs to the entire adoption, not to any one scope." It is the fallback for cross-cutting artefacts and maps to the repo root's feedback inbox (typically `governance/feedback.md`).

A scope reference is always lowercase and hyphen-separated, matching the folder name convention. Examples: `cluster/product-development`, `function/revenue`, `project/agentic-coach-phase-3`, `module/ai-factory`, `programme`.

### Type inference rules

The catalogue agent determines a scope's type by applying three inference layers in order:

**1. Parent directory convention (primary).** The scope's type is inferred from which structural folder it lives under:

| Parent folder | Inferred type |
|---|---|
| `clusters/` | `cluster` |
| `functions/` | `function` |
| `projects/` | `project` |
| Any folder declared as `module_paths` in the manifest or extension | `module` |

This covers the majority of scopes without any per-folder configuration.

**2. README.md frontmatter `type:` field (override).** When a scope's `README.md` carries a `type:` field in its YAML frontmatter, that value overrides the parent-directory inference. This covers edge cases: a folder under an unconventional path, or a module that lives in a location not covered by a `module_paths` declaration.

```yaml
# clusters/ai-capability/README.md
---
type: module
slug: ai-capability
---
```

The override is explicit and local to the scope. Agents read the first 20 lines of `README.md` when scanning the scope to detect it.

**3. Manifest scope declarations (fallback).** When neither parent-directory convention nor README frontmatter resolves the type, the agent consults the manifest's `scope_registry` extension (if declared) for an explicit mapping of path to type. This covers adopter-specific layouts that diverge from standard conventions.

Type inference fails (produces `type: unknown`) only when all three layers are exhausted without a match. The catalogue records the entry as `status: unknown-type` and the `[scope-unknown-type]` warning is surfaced to the manifest owner.

### Scope discovery

The catalogue agent discovers scopes by walking the structural folders. The discovery rules by type:

**Clusters** — every immediate subdirectory of `clusters/` (the adopter-declared cluster root), excluding:
- `context/` — source material, not a scope
- `_template/` — scaffold templates
- `closed/` — closed scopes (included separately as `status: closed`; see [Closed scope lifecycle](#closed-scope-lifecycle))
- Any name beginning with `_` or `.`

**Functions** — every immediate subdirectory of `functions/` (the adopter-declared function root), excluding `context/`, `_template/`, `closed/`, and names beginning with `_` or `.`.

**Projects** — every immediate subdirectory of `projects/` (the adopter-declared project root), excluding `context/`, `_template/`, `closed/`, and names beginning with `_` or `.`.

**Modules** — folders declared in the manifest's `module_paths` extension field, or folders matching known module patterns (`ai-factory/`, `cloudops/`), or folders whose `README.md` carries `type: module` in its frontmatter. The module type is the most heterogeneous — modules do not share a single parent folder — and therefore relies more on explicit declarations than on path convention.

**Programme** — always present as exactly one entry per adoption. It is not discovered by walking; it is synthesised by the agent. The programme entry has `slug: programme`, `path: .`, and `feedback_inbox` pointing to the repo-wide governance inbox (typically `governance/feedback.md`). The lead is the manifest owner.

**Discovering lead.** For each discovered scope, the agent reads the scope's `people.md` (if present) and extracts the Lead table's first row. If no `people.md` exists or the lead table is empty, the lead field is recorded as `TBD`.

**Discovering feedback inbox.** For each discovered scope, the agent checks for a `feedback.md` file at the scope root. If found, `feedback_inbox` is set to that relative path. If absent, `feedback_inbox` is recorded as `null`. Agents that need to route to a scope with `feedback_inbox: null` fall back to the nearest parent scope's inbox (see [Resolution contract for agents](#resolution-contract-for-agents)).

### `scopes.yaml` schema

The catalogue file is a YAML document written at the adopter-declared catalogue path (default: `governance/catalogue/scopes.yaml`). The file is machine-generated; do not edit by hand.

```yaml
generated: YYYY-MM-DDTHH:MMZ
generator: scope-registry
spec_version: <open-org-spec version>
source_files:
  - clusters/
  - functions/
  - projects/
  - ai-factory/
  - .
scopes:
  - type: cluster
    slug: product-development
    path: clusters/product-development
    feedback_inbox: clusters/product-development/feedback.md
    lead: Yaiza Temprado
    status: active
  - type: function
    slug: revenue
    path: functions/revenue
    feedback_inbox: functions/revenue/feedback.md
    lead: Howard Tunnicliffe
    status: active
  - type: project
    slug: agentic-coach-phase-3
    path: projects/agentic-coach-phase-3
    feedback_inbox: projects/agentic-coach-phase-3/feedback.md
    lead: TBD
    status: active
  - type: project
    slug: busuu-mcp
    path: projects/closed/busuu-mcp
    feedback_inbox: null
    lead: TBD
    status: closed
  - type: module
    slug: ai-factory
    path: ai-factory
    feedback_inbox: ai-factory/feedback.md
    lead: Javier Fernandez
    status: active
  - type: programme
    slug: programme
    path: .
    feedback_inbox: governance/feedback.md
    lead: Javier Fernandez
    status: active
```

**Fields per entry:**

| Field | Source | Notes |
|---|---|---|
| `type` | Inferred from parent folder, README frontmatter, or manifest declaration | Closed vocabulary: `cluster \| function \| project \| module \| programme` |
| `slug` | Folder name of the scope; `programme` for the repo root | Unique within its type |
| `path` | Relative path from repo root to the scope folder | `.` for programme |
| `feedback_inbox` | Relative path to the scope's `feedback.md`; `null` if absent | |
| `lead` | Full name from the Lead table in `people.md`; `TBD` if absent | |
| `status` | `active \| closed` — inferred from the scope's spec `status:` frontmatter, or `closed` if the folder is under `closed/` | |

**Top-level fields:**

| Field | Meaning |
|---|---|
| `generated` | ISO 8601 timestamp of catalogue generation in UTC |
| `generator` | Always `scope-registry` |
| `spec_version` | The open-org-spec version this catalogue was generated against |
| `source_files` | The root paths that were walked to discover scopes; aids debugging and staleness assessment |

The `source_files` list records exactly which root paths were walked. When an adopter adds a new structural folder (e.g., a new `functions/` root), the absence of that path from `source_files` in an existing catalogue signals that the catalogue predates the folder and a regeneration is needed.

### Primary scope resolution

A person may hold a Lead role in more than one scope simultaneously (e.g., a module owner who is also a cluster lead). When the scope registry records a lead, it records the name as stated in each scope's `people.md` independently — the same person appears as lead in multiple entries.

When an agent needs to determine a person's *primary* scope — the scope whose feedback inbox should receive a message addressed specifically to that person — it applies this resolution order:

1. The scope where the person holds the highest-authority function in the `people` capability's closed vocabulary, ranked: **Owner > Lead > Driver > Approver > Liaison > Contributor > Member**.
2. If tied on function rank, the scope that is **shallower in the repo tree** (fewer path segments from root). A cluster lead beats a project lead when both are `Lead`, because the cluster is the more structural scope.
3. If still tied, the scope that appears **first alphabetically** by path. This is a deterministic tiebreaker, not a semantically meaningful one; if the ordering matters, the adopter should disambiguate the person's `people.md` entries.

Primary scope resolution is used by agents that send a single targeted message to a person rather than to a scope. The `[primary-scope-tie]` warning is emitted when the final tiebreaker (alphabetical) is required, to prompt the adopter to clarify.

### Resolution contract for agents

Any agent that needs to resolve a scope reference to a feedback inbox follows this contract:

1. **Read `governance/catalogue/scopes.yaml`** (or the adopter-declared catalogue path).
2. **Look up the entry by `type` + `slug`** (or by the bare word `programme` for programme-level artefacts).
3. **Use the entry's `feedback_inbox`** as the routing target. If `feedback_inbox` is `null`, walk up the path hierarchy: check the parent folder, then its parent, until a scope with a non-null `feedback_inbox` is found, or fall back to `governance/feedback.md`.
4. **`[catalogue-miss]` fallback.** If the reference is not found in the catalogue (type/slug pair absent), log a `[catalogue-miss]` warning and fall back to walking the repo directly to find a matching folder. If the direct walk also fails, route to `governance/feedback.md` and log a `[scope-not-found]` warning.
5. **`[catalogue-stale]` warning.** If the catalogue's `generated` timestamp is older than 25 hours, log a `[catalogue-stale]` warning and proceed using the catalogue data. Do not refuse to route — a stale catalogue is better than no catalogue. The warning prompts the adopter to schedule a regeneration.
6. **Skip `status: closed` entries.** Agents never route to a closed scope's feedback inbox. When a reference resolves to a `status: closed` entry, log a `[scope-closed]` warning and route to the nearest active ancestor scope's inbox instead.

The 25-hour staleness window is chosen to accommodate daily regeneration with a one-hour tolerance for scheduled delays. Adopters who regenerate more frequently may tighten this in their extension spec; the default is permissive to avoid false warnings.

### Delta/incremental mode

The catalogue agent supports two execution modes:

**Full scan (default and first-run).** Walk all structural folders, discover all scopes, regenerate `scopes.yaml` from scratch. Used on the first run, when `scopes.yaml` does not yet exist, and when invoked explicitly with `--full`.

**Delta mode (fast-path).** On subsequent runs, the agent reads the `generated` timestamp from the existing `scopes.yaml` and queries the git log for commits that touched structural folders since that timestamp:

```
git log --since="<generated timestamp>" --name-only -- clusters/ functions/ projects/ <module_paths>
```

If the git log is available and the output includes any changed paths under structural folders, the agent re-scans only those scopes and merges the updated entries into the existing catalogue. Scopes not touched by commits since the last generation are carried forward unchanged.

**Fall back to full scan** when:
- `scopes.yaml` does not exist (first run).
- The git log is unavailable (detached HEAD, shallow clone, no git history).
- The `source_files` list in the existing catalogue does not match the current structural roots (a new folder root was added to the manifest).
- The `spec_version` in the existing catalogue does not match the current standard version.

Delta mode reduces token and I/O cost for large repos with frequent regeneration. The correctness contract is the same as full scan: the output of a delta run is identical to a full scan given the same repo state.

### Closed scope lifecycle

Closed scopes — projects with `status: closed` in their spec frontmatter, or any scope that has been moved to a `closed/` subfolder — are included in `scopes.yaml` with `status: closed`. They are never removed from the catalogue when closed; removal would break historical references.

**Behaviour of closed entries:**

- The `feedback_inbox` field is recorded as it existed at close time (or `null` if the inbox was not present). It is not updated after close.
- Agents skip `status: closed` entries as routing targets (see Step 6 of the [Resolution contract for agents](#resolution-contract-for-agents)).
- `/adhere-to scope-registry` surfaces any artefact that still carries a reference to a closed scope as a `warning` severity gap, with the message: "scope reference `<type>/<slug>` resolves to a closed scope — update to the surviving scope or `programme` if no successor exists."
- Closed entries accumulate indefinitely. A full-scan regeneration discovers them under `closed/` subfolders and re-records them. Delta mode carries them forward unchanged (since the folders inside `closed/` are excluded from the delta scan's structural walk, only a full scan updates them).

The persistence of closed entries in the catalogue is intentional: artefacts authored before the scope closed — risks, decisions, feedback entries — may still reference the closed scope. Those references should surface a warning, not silently route to an incorrect inbox.

## Artefacts

The scope registry generates `scopes.yaml` on a daily schedule. No additional infrastructure files are required. `adhere-to scope-registry` scaffolds the catalogue path if it does not exist.

```yaml
artefacts:
  - id: scopes-yaml
    type: generated_file
    path: governance/catalogue/scopes.yaml
    variables:
      - name: catalogue_base_path
        source: extension#catalogue_base_path
        default: governance/catalogue
    description: >
      Machine-generated scope catalogue. Written by the scope registry agent.
      Never edited by hand. Path is adopter-configurable via the extension's
      catalogue_base_path field; default is governance/catalogue/scopes.yaml.
    check:
      type: file_exists
      path: "{{catalogue_base_path}}/scopes.yaml"
      on_missing: warn
      message: >
        scopes.yaml not found at {{catalogue_base_path}}/scopes.yaml.
        Run /adhere-to scope-registry to generate it, or trigger the
        scope registry agent if it is configured as a scheduled job.
```

The `on_missing: warn` severity (rather than `error`) reflects that a missing catalogue is recoverable by running the agent; it is not a broken governance contract, only an ungenerated index.

## What is not prescribed

- **The hosting service or CI platform for scheduled regeneration.** The catalogue agent can run as a GitHub Actions workflow, a Claude Code scheduled task, a cron job, or on-demand. The standard defines the contract (inputs, outputs, delta behaviour) but not the runtime.
- **The number or types of scopes in an adoption.** An adoption with no functions, or no projects, or only a single cluster, is fully conformant. The catalogue records whatever scopes exist; an empty type is not a gap.
- **Whether every scope has a `feedback.md`.** Scopes without a feedback inbox are recorded with `feedback_inbox: null`. The standard requires the field to be present in the catalogue; it does not require the file to exist. Agents handle the null case via the fallback chain in the resolution contract.
- **Whether the scope registry is the only way to discover scopes.** Agents may walk the repo directly as a fallback (see the `[catalogue-miss]` fallback in the resolution contract). The catalogue is the fast path, not the only path. Adopters who do not run the agent on a schedule can still satisfy capability dependencies by running `/adhere-to scope-registry` on demand.
- **A specific schema for the `people.md` lead table.** The scope registry reads the lead from `people.md` using the conventions of the [`people`](../people/spec.md) capability if active, or by reading the first header row of the lead table otherwise. The `people` capability is not a hard dependency; the lead field degrades to `TBD` when the table cannot be parsed.
- **The exact timestamp format beyond ISO 8601.** The `generated` field is ISO 8601 in UTC. The time component resolution (seconds, minutes) is adopter-dependent; the 25-hour staleness window is evaluated against the full timestamp.

## Rationale

**The standard defines structural types but has no way to reference a specific scope instance.** The vocabulary of structural types — cluster, function, project, module — exists across multiple capability specs. What is missing is a canonical way for an artefact to say "I belong to *this specific* cluster" or "this risk relates to *this specific* function." Without it, every reference is either a fragile path string (breaks when folders move) or an implicit inference from file location (breaks when artefacts are cross-cutting or live at the programme level).

**A path string is the wrong reference type.** A risk that declares `scope: clusters/product-development` is coupled to a folder structure that can change. A risk that declares `scope: cluster/product-development` is coupled to a logical scope identity — the cluster named `product-development` — which survives folder renames, structural reorganisations, and migrations. The type/slug pair is the stable identity; the path is a derived property.

**Routing requires resolving type/slug to a feedback inbox.** The `risk-scope-field` proposal (and the conformance agent, and any future artefact routing) needs to answer: "given `scope: function/revenue`, what is the feedback inbox?" That resolution requires knowing that `function/revenue` maps to `functions/revenue/feedback.md` in this adoption. The scope registry provides that mapping as a single file read. Without it, agents either hardcode adopter-specific paths (wrong — not generic) or walk the repo to discover them (slow, fragile).

**The adoption manifest is not the right home for scope instances.** The manifest declares which capabilities are active — governance policy. Scope instances are operational content: which clusters, functions, and projects exist in this adoption right now. The manifest is a governance artefact owned by one person and not intended as a queryable registry. Separating them keeps the manifest stable and small, while the scope registry evolves as the adoption grows.

**The scope registry is the instance-level complement to the manifest's type-level vocabulary.** The manifest says "the `cluster` structural type is active." The scope registry says "the active clusters are: product-development, customer-acquisition-growth, customer-lifecycle." The two layers together give a complete picture: the types and the instances.

**Validated by a concrete chain of failures.** Programme-level risks were routed to the governance owner because the scanner could not determine which scope's feedback inbox to target. The `risk-scope-field` capability provides the declaration; the scope registry provides the resolution. Both are required to make risk routing correct.

## Related

- [`../adoption-manifest/spec.md`](../adoption-manifest/spec.md) — declares the structural type vocabulary; the scope registry provides the instance-level index that complements it.
- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — declares decision authority within a scope; the scope registry declares which scopes exist.
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — the feedback inbox convention that this capability indexes; `feedback_inbox` entries in the catalogue point to `feedback.md` files conforming to this capability.
- [`../risk-at-scope/spec.md`](../risk-at-scope/spec.md) — primary consumer of scope references; risks declare `scope: <type>/<slug>` resolved via this catalogue.
- [`../people/spec.md`](../people/spec.md) — the lead table read by the catalogue agent to populate the `lead` field; optional dependency.
- [`../observability/spec.md`](../observability/spec.md) — the observability extension's scope tree is a precursor to this capability; the scope registry formalises and generalises scope discovery.
- [`../tooling/catalogue/spec.md`](../tooling/catalogue/spec.md) — the general catalogue agent; `scopes.yaml` is a sibling sub-catalogue alongside `specs.yaml`, `decisions.yaml`, and `feedback-inboxes.yaml`.
