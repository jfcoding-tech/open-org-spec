# Spec-Health: Catalogue Agent

**Owner:** Javier Fernandez
**Status:** Active

Part of the [spec-health suite](../spec.md). Regenerates the adopter's spec catalogue from the current state of all specs in the repo, commits the result, and pushes. Ensures the catalogue never drifts from the canonical markdown files.

## Purpose

A spec catalogue is only useful when it is current. A daily automated regeneration, committed at a predictable time, eliminates the manual step of keeping the catalogue in sync and provides a reliable single read-target for downstream agents and commands — so any consumer reads one file rather than walking the filesystem.

## Inputs

- Spec paths to catalogue (extension point — which folder trees to include)
- Catalogue file path (extension point — where to write the output)
- Catalogue schema (extension point — the shape of the generated file)
- Commit message format (extension point)

## Pattern

### Step 1 — Sync

Before any write, verify the repo is in a state safe to write to. On failure, apply the [suite retry contract](../spec.md#retry-contract).

### Step 2 — Walk governed spec paths

Walk all adopter-declared spec paths. For each spec file found, classify by type:

- `spec` — files named `spec.md` or matching a spec-path pattern
- `decision` — files under `decisions/` folders
- `feedback` — files named `feedback.md`
- `project` — files under `projects/` folders
- `module` — cluster or factory-level README or top-level spec

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

### Step 6 — Write, commit, push

Write the full catalogue to the adopter-declared catalogue path, overwriting the previous version. Commit using the adopter-declared commit message format. Push.

### Step 7 — Log invocation

Implements the observability contract per the [suite spec](../spec.md#observability-contract). Append one entry to the adopter-declared invocation log:

```
YYYY-MM-DD HH:MM UTC | catalogue-update-agent | files_read: N | catalogue_assisted: false | outcome: success/fail
```

`catalogue_assisted: false` — this agent generates the catalogue; it does not consume it.

### Implements shared contracts

This agent implements the retry contract and observability contract per the [suite spec](../spec.md#shared-contracts).

## Data contracts

**Invocation log entry format** (per suite spec):

```
YYYY-MM-DD HH:MM UTC | catalogue-update-agent | files_read: N | catalogue_assisted: false | outcome: success/fail
```

**Catalogue entry shape** (per-spec row in the output file):

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

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Spec paths to walk | Folder trees to include in the catalogue | *(required)* |
| Catalogue file path | Where to write the output | *(required)* |
| Catalogue schema | Shape of the generated file | *(required)* |
| Commit message format | Template for the automated commit | `chore: regenerate catalogue — YYYY-MM-DD` |

## Rationale

The catalogue is the primary mechanism by which downstream agents avoid walking the filesystem. Its value is directly proportional to its freshness. The deliberate sequencing — conformance first, then catalogue — means any fix a contributor makes after receiving a morning nudge is captured in the same day's snapshot.

## Related

- [`../spec.md`](../spec.md) — suite spec; shared contracts (scheduling, retry, observability)
- [`../conformance/spec.md`](../conformance/spec.md) — runs before this agent; fixes it produces are captured in this agent's snapshot
- [`../observability/spec.md`](../observability/spec.md) — reads the catalogue for open-gap counts
- [`../implementations/README.md`](../implementations/README.md) — runtime contract
