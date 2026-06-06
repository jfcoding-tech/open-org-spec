# Catalogue

**Owner:** Javier Fernandez
**Status:** Active

A standalone tooling capability. The catalogue agent generates and maintains the repo's queryable index of all specs, decisions, feedback inboxes, and projects. It is infrastructure — consumed by every other agent and command that needs to know what exists in the repo without walking the filesystem.

## Purpose

A spec-driven repository is only cheaply queryable when its state is projected into a structured index. Walking the filesystem on every tool invocation is slow and token-expensive; a single regenerated index lets any consumer read one file (or one sub-file) rather than re-deriving the repo's shape each time.

The catalogue is the primary mechanism by which downstream agents avoid walking the filesystem. Its value is directly proportional to its freshness, so it is regenerated on a daily schedule and committed at a predictable time. Any consumer — the conformance agent, observability tools, decision-escalation, catchup, adherence-check — reads the catalogue rather than the raw markdown.

## Inputs

- Spec paths to walk (extension point — which folder trees to include)
- Catalogue base path (extension point — where the index and sub-files are written)
- Catalogue schema (extension point — the shape of the generated files)
- Commit message format (extension point)

## Split catalogue output format

The catalogue is written as a **split set of files** under the adopter-declared catalogue base path:

```
governance/catalogue/
  index.yaml              ◄── discovery manifest
  specs.yaml              ◄── one entry per spec
  decisions.yaml          ◄── one entry per decision record
  feedback-inboxes.yaml   ◄── one entry per feedback.md
  projects.yaml           ◄── one entry per project
```

- **`index.yaml`** is the discovery manifest. It lists every sub-catalogue, its relative path, the count of entries it holds, and the timestamp at which it was last generated. A consumer reads `index.yaml` first to discover what sub-catalogues exist and how fresh each is.
- **Sub-files** each hold the entries for one artefact type. A tool that needs only one type (e.g. decision-escalation needs only decisions) reads that sub-file directly and skips the rest. A tool that needs everything reads `index.yaml` and follows it to each sub-file.

This split keeps the read cost proportional to the consumer's need: a single-type consumer never pays to parse the whole repo's projection.

### `index.yaml` shape

```yaml
generated: <YYYY-MM-DD HH:MM UTC>
spec_version: <version>
sub_catalogues:
  - type: specs
    path: specs.yaml
    entries: <N>
    generated: <YYYY-MM-DD HH:MM UTC>
  - type: decisions
    path: decisions.yaml
    entries: <N>
    generated: <YYYY-MM-DD HH:MM UTC>
  - type: feedback-inboxes
    path: feedback-inboxes.yaml
    entries: <N>
    generated: <YYYY-MM-DD HH:MM UTC>
  - type: projects
    path: projects.yaml
    entries: <N>
    generated: <YYYY-MM-DD HH:MM UTC>
```

## Pattern

### Step 1 — Sync

Before any write, verify the repo is in a state safe to write to. On a transient failure (a write conflict, a push that fails because the branch diverged, a network error), re-attempt rather than waiting for the next scheduled window. The maximum number of attempts is adopter-declared (default 3); on exhaustion, record the failure in the adopter-declared failure log and stop.

### Step 2 — Walk governed spec paths

Walk all adopter-declared spec paths. For each file found, classify by type:

- `spec` — files named `spec.md` or matching a spec-path pattern → `specs.yaml`
- `decision` — files under `decisions/` folders → `decisions.yaml`
- `feedback` — files named `feedback.md` → `feedback-inboxes.yaml`
- `project` — files under `projects/` folders → `projects.yaml`
- `module` — cluster or factory-level README or top-level spec → `specs.yaml`

### Step 3 — Extract spec fields

For each spec file, extract:

- `path` — relative from repo root
- `type` — from classification above
- `scope` — inferred from path (cluster name, factory, project name, etc.)
- `owner` — from `**Owner:**` or `Owner:` in the first 20 lines
- `status` — from `**Status:**` or `Status:` in the first 20 lines
- `last_edited` — from the version control history for that file
- `related` — links extracted from a `## Related` section if present

### Step 4 — Extract decision fields

For each decision record, extract: `path`, `scope`, `owner`, `status`, `last_edited`, and any `affects:` or `supersedes:` cross-references from the first 30 lines.

### Step 5 — Extract feedback inbox fields

For each `feedback.md`, extract: `path`, `scope`, primary addressee (the most frequently named `→ <name>` target in the file), and open entry count (headings that do not contain `[resolved]`).

### Step 6 — Write sub-files and index, commit, push

Write each sub-file (`specs.yaml`, `decisions.yaml`, `feedback-inboxes.yaml`, `projects.yaml`) to the adopter-declared catalogue base path, overwriting the previous version. Write `index.yaml` last, listing every sub-catalogue with its path, entry count, and generation timestamp. Commit using the adopter-declared commit message format. Push.

### Step 7 — Log invocation

Append one entry to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | catalogue | files_read: N | catalogue_assisted: false | outcome: success/fail
```

`catalogue_assisted: false` — this agent generates the catalogue; it does not consume it.

## Data contracts

**Invocation log entry format:**

```
YYYY-MM-DD HH:MM UTC | catalogue | files_read: N | catalogue_assisted: false | outcome: success/fail
```

**Catalogue entry shape** (per-spec row in `specs.yaml`):

```yaml
- path: <relative path from repo root>
  type: <spec | decision | feedback | project | module>
  scope: <inferred scope name>
  owner: <extracted owner or empty string>
  status: <extracted status or empty string>
  last_edited: <date>
  related: [<list of linked paths>]
```

Missing fields are written as empty strings, not omitted. The catalogue is a projection of reality, including gaps — missing fields are a signal for the conformance agent to handle, not an error for this agent.

## Scheduling

Daily (adopter-declared). The catalogue regenerates once per day at the adopter's chosen time. When the catalogue is consumed by the spec-health conformance agent, the adopter typically schedules conformance to run first so that same-day fixes a contributor makes after a morning nudge are captured in the day's snapshot.

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Spec paths to walk | Folder trees to include in the catalogue | *(required)* |
| Catalogue base path | Where the index and sub-files are written | *(required)* |
| Catalogue schema | Shape of the generated files | *(required)* |
| Commit message format | Template for the automated commit | `chore: regenerate catalogue — YYYY-MM-DD` |
| Schedule | When the catalogue agent fires | Daily |

## Rationale

The catalogue is the cheap query layer the whole repo's tooling depends on. Splitting the output into an index plus per-type sub-files means a consumer pays only for what it reads: a decision-only tool parses `decisions.yaml` and nothing else; a full-repo consumer follows `index.yaml`. The daily regeneration cadence keeps the projection fresh enough that consumers can trust it rather than falling back to a filesystem walk, while the index's per-sub-catalogue timestamps let a consumer detect staleness (e.g. refuse the fast-path if the relevant sub-file is older than its freshness window).

## Related

- [`../spec.md`](../spec.md) — the tooling capability; delta mode and self-contained command conventions.
- [`../spec-health/spec.md`](../spec-health/spec.md) — the spec-health suite, which depends on this capability for its catalogue read-target.
- [`../spec-health/conformance/spec.md`](../spec-health/conformance/spec.md) — primary consumer; reads the catalogue rather than walking the filesystem.
- [`../agent-metrics/spec.md`](../agent-metrics/spec.md) — reads the catalogue for open-gap counts.
