# Scope Registry Agent

**Owner:** Javier Fernandez
**Status:** Draft
**Type:** Command

A tool of the scope-registry capability. Walks the adopter's structural folders, discovers all active and closed scopes, and writes `governance/catalogue/scopes.yaml` — the machine-generated index that any agent reads to resolve a `<type>/<slug>` reference to a feedback inbox without walking the filesystem.

## Purpose

The scope registry catalogue is the single file that lets downstream agents answer "given `scope: function/revenue`, what is the feedback inbox?" with one read rather than a folder traversal. Every time an agent routes a risk, checks a person's primary scope, or validates a scope reference, it relies on the catalogue being present and fresh.

Without a generation agent, the catalogue must be maintained by hand. Hand-maintained catalogues drift: scopes are added and never registered, slugs are renamed and the old entry lingers, leads change and the catalogue still names the previous person. The generation agent eliminates that drift by deriving the catalogue mechanically from the structural folders that contributors already maintain.

The agent does not own the content it reads. It reads what contributors have written in their `README.md`, `people.md`, and `spec.md` files and projects that state into a structured index. When the source files are correct, the catalogue is correct. When the source files have gaps (no `people.md`, no `feedback.md`), the catalogue records those gaps faithfully rather than fabricating values.

## Pattern

### Inputs

- **Capability slug** — `scope-registry`. Used to verify the capability is active before proceeding.
- **Target** — optional. A single structural folder path (e.g. `functions/revenue`) to limit the scan to one scope. Useful for incremental validation after a single scope is created or renamed.
- **Mode** — optional. One of:
  - `full` (default) — walk all structural folders declared in the adoption; rebuild the entire catalogue.
  - `delta` — use `git log` to find structural folders changed since the catalogue was last generated; re-scan only those. Falls back to `full` on first run or if the git log is unavailable.
  - `dry-run` — compute the full catalogue in memory but do not write or commit; surface the summary only.

---

### Step 0 — Verify state

Read the adoption manifest at `.open-org-spec/config.yaml`. Verify:

- The manifest exists. Refuse if not — redirect to `oos:adopt-manifest`.
- The `scope-registry` capability is declared in the manifest. Refuse if absent — redirect to `oos:adopt-scope-registry`.
- The capability's status is `active` or `proposed`. Refuse if `inactive` — there is nothing to generate.

Then read the scope-registry capability spec at `open-org-spec/specs/scope-registry/spec.md`. If the manifest declares an `extension` for the capability, read that extension too. The extension may declare:

- **Structural folder overrides** — which top-level directories map to which structural types (`clusters/`, `functions/`, `projects/`, etc.). If absent, use the defaults defined in Step 2.
- **Catalogue output path** — where to write `scopes.yaml`. If absent, use `governance/catalogue/scopes.yaml`.
- **Additional exclusion patterns** — folder names to exclude from discovery in addition to the defaults.
- **Module declarations** — explicit list of module-type scopes that do not live under a conventional folder (e.g. `ai-factory/`).

Read the manifest's `owner` field — this is the fallback `lead` value for the programme entry and for any scope whose `people.md` has no Lead row.

---

### Step 1 — Determine scope discovery strategy

**Full mode (default):** Discover all structural folders declared by the manifest (or by extension defaults). The full set of folders to walk is established in Step 2.

**Delta mode:** Read the `generated:` timestamp from the existing `governance/catalogue/scopes.yaml` (or the adopter-declared output path). If the file does not exist or the timestamp is absent, fall back to full mode and record a `[delta-fallback: no-prior-catalogue]` note in the summary.

Run:

```bash
git log --since="<generated-timestamp>" --name-only --format="" -- \
  clusters/ functions/ projects/ <module-paths>
```

Extract the unique top-level structural folder prefixes from the changed file paths. Only those prefixes are re-scanned in Step 2. Scopes not touched since the last generation are carried forward verbatim from the existing catalogue.

If `git log` fails (not a git repo, no commits, network error), fall back to full mode and record a `[delta-fallback: git-log-error]` note.

**Dry-run mode:** Proceed through all steps as in full mode. Skip Step 5's write and commit. Surface the summary at Step 6 with a `[dry-run: no files written]` notice.

---

### Step 2 — Walk structural folders

For each structural type declared by the manifest (or its defaults), enumerate the immediate subdirectories of the type's root folder. Exclude:

- `closed/` — closed scopes are discovered separately (see below).
- `_template/` — template directories are not scope instances.
- `context/` — source-material folders are not scope instances.
- `governance/` — governance folders under a structural root are not scope instances.
- Any additional patterns declared in the manifest extension.

**Default structural folder mappings:**

| Structural type | Root folder |
|---|---|
| `cluster` | `clusters/` |
| `function` | `functions/` |
| `project` | `projects/` |
| `module` | Declared explicitly in manifest extension (e.g. `ai-factory/`) |

**Module discovery.** Modules do not share a conventional root folder. Discover them from:
1. The manifest extension's `module_paths` list (explicit declarations).
2. Known module patterns — any folder at the repo root containing a `README.md` with `type: module` in its frontmatter.

If neither source yields a module list, no module entries are created. No fabrication.

**Closed scopes.** Walk `<type-root>/closed/` for each structural type that has a `closed/` subfolder. Every immediate subdirectory of `closed/` is a scope entry with `status: closed`. Scopes discovered via a `closed/` subfolder do not need a `status:` field in their `spec.md` — their location is sufficient to determine `status: closed`.

**Type inference.** The structural type of a discovered directory is:

1. **Primary: parent folder location.** A directory found under `clusters/` is type `cluster`; under `functions/` is type `function`; under `projects/` is type `project`.
2. **Override: README.md frontmatter.** If the directory contains a `README.md` with a `type:` field in its YAML frontmatter, that value overrides the location-inferred type. This handles edge cases (e.g. a function that has been moved or a module living inside a cluster folder by adopter convention).

**Programme scope.** Always generate exactly one `programme` entry. It is not discovered from the filesystem — it is implicit. Its `path` is `.` (the repo root), its `feedback_inbox` is `governance/feedback.md` (or the adopter-declared programme inbox), and its `lead` is the manifest's `owner` field value. Its `status` is always `active`.

---

### Step 3 — Build scope entries

For each discovered directory, build one scope entry. The entry is built by reading the scope's source files — no values are guessed or inferred beyond what is explicitly written.

**Slug.** The folder name of the scope directory. For scopes in `closed/`, the slug is the folder name within `closed/` (e.g. `projects/closed/busuu-mcp/` → slug `busuu-mcp`).

**Path.** Relative path from the repo root to the scope directory (e.g. `functions/revenue`). For closed scopes under a `closed/` subfolder, the path includes `closed/` (e.g. `projects/closed/busuu-mcp`).

**Lead.** Read `<scope-path>/people.md`. Look for the Lead role row in the role table. The Lead is the person in the `Current holder` column for the row where `Role` is `Lead`. If `people.md` does not exist, or it exists but has no Lead row, or the Lead row has no current holder, write `TBD`.

**Feedback inbox.** Check whether `<scope-path>/feedback.md` exists. If it does, write the relative path. If it does not, write `null`. Do not create the file — its absence is a gap for `adhere-to` to surface, not for this agent to fix.

**Status.** Determined by one of the following, in order of precedence:

1. If the scope was found in a `closed/` subfolder: `closed`.
2. If `<scope-path>/spec.md` exists and its YAML frontmatter contains a `status:` field: use that value, normalised to lowercase. Values `active`, `draft`, and `proposed` are treated as `active` for routing purposes; `closed`, `archived`, and `deprecated` are treated as `closed`.
3. If `<scope-path>/README.md` exists and its YAML frontmatter contains a `status:` field: use that value (same normalisation).
4. If no `spec.md` or `README.md` with a `status:` field is found: write `active` and record a `[status-inferred: no-spec]` warning in the summary.

**Missing source files.** If a scope directory exists but contains neither `README.md`, `people.md`, nor `spec.md`, include the scope entry with all extractable fields set and unextractable fields written as `null` or `TBD`. Record a `[sparse-scope: <slug>]` warning in the summary. Sparse scopes are included in the catalogue — their presence in the filesystem is real.

---

### Step 4 — Resolve lead for multi-scope appearances

Some people hold roles across more than one scope. This step ensures the catalogue records each person's primary scope correctly for consumers that need to route to a person's home scope (e.g. the people-catalogue capability).

This step does not modify `feedback_inbox`, `lead`, or `status` values — it only adds a `primary_scope` field to people entries in the separate people-catalogue, if that capability is also active. For `scopes.yaml`, the `lead` field is already per-scope; no resolution is needed.

If the `people-catalogue` capability is not active, skip this step entirely.

When `people-catalogue` is active, for any person appearing as Lead, Owner, or a named role holder across multiple scopes, determine their primary scope by applying the authority order: `Owner` > `Lead` > `Driver` > `Approver` > `Liaison` > `Contributor` > `Member`. If the same authority level appears in multiple scopes, resolve ties by shallowest repo depth (fewest path segments). Record the primary scope as the `type/slug` reference for that person in the people-catalogue output.

---

### Step 5 — Write scopes.yaml

Assemble all scope entries (including the programme entry) and write `governance/catalogue/scopes.yaml` (or the adopter-declared output path).

**File format:**

```yaml
generated: YYYY-MM-DDTHH:MMZ
source_files:
  - <list of all files read during this run, relative from repo root>
scopes:
  - type: <structural type>
    slug: <folder name>
    path: <relative path from repo root>
    feedback_inbox: <relative path to feedback.md, or null>
    lead: <lead name or TBD>
    status: <active | closed>
```

**Ordering.** Entries are ordered by type first (programme, cluster, function, module, project), then alphabetically by slug within each type. Ordering is deterministic so diffs are readable.

**source_files field.** Lists every file the agent read during this run. This is the observability record for the generation — it lets a reviewer confirm the agent read what it should have and nothing else. It also enables the delta mode in the next run to verify which paths contributed to the current state.

**Closed scopes.** Included in the output with `status: closed`. They appear after active scopes of the same type in the ordering.

**Overwrite semantics.** The file is always written in full, not appended. In delta mode, the prior catalogue is read, the re-scanned entries are updated, and the merged result is written in full. This ensures the output file is always a complete, self-consistent snapshot.

In `dry-run` mode: skip this step. Output the would-be content to the summary instead.

---

### Step 6 — Commit

Stage the output file:

```bash
git add governance/catalogue/scopes.yaml
```

(Or the adopter-declared output path, if different.)

Commit with the message:

```
chore: scope-registry catalogue — YYYY-MM-DD
```

Where `YYYY-MM-DD` is today's UTC date.

In `dry-run` mode: skip this step.

On push failure: apply the standard retry loop — `git pull --rebase`, then retry push — up to 3 attempts with a 30-second sleep between attempts. On exhaustion, append to the failure log and exit 1.

---

### Step 7 — Log invocation

Append one entry to the adopter-declared invocation log:

```
- YYYY-MM-DD HH:MM UTC | /scope-registry | files_read: N | catalogue_assisted: false | outcome: success/fail | spec_version: <version>
```

`catalogue_assisted: false` — this agent generates the scope catalogue; it does not consume it to discover scopes. If the agent reads `governance/catalogue/scopes.yaml` to carry forward entries in delta mode, it sets `catalogue_assisted: true`.

`spec_version` — the `canonical_spec_version` from the command file's frontmatter, if present.

---

### Step 8 — Surface summary

At the end of the run, surface:

- **Mode**: full / delta / dry-run.
- **Scopes discovered**: N total (N active, N closed), broken down by type.
- **Delta re-scanned** (delta mode only): N scopes re-scanned; N carried forward from prior catalogue.
- **Warnings**: list of `[status-inferred]`, `[sparse-scope]`, `[delta-fallback]` notices encountered during the run.
- **Output**: path written, or `[dry-run: no files written]`.
- **Next steps**: if warnings are present, name the scopes that need attention. If no warnings, confirm the catalogue is ready for consumers.

---

## Delta mode detail

Delta mode is the efficient path for adopters with large repos or frequent commits. The logic:

1. Read the `generated:` timestamp from the existing catalogue.
2. Run `git log --since=<timestamp> --name-only --format="" -- <structural-roots>`.
3. Extract unique structural folder prefixes from the changed paths. A changed path `functions/revenue/people.md` identifies `functions/revenue` as a scope to re-scan.
4. Re-run Steps 2–3 for the identified scopes only.
5. Merge updated entries into the prior catalogue: replace entries whose slug matches a re-scanned scope; leave all other entries unchanged.
6. Write the merged result and commit as normal.

**Fallback conditions** — any of the following triggers a full-mode fallback:

- No prior catalogue exists.
- The prior catalogue's `generated:` field is absent or unparseable.
- `git log` exits non-zero.
- The `generated:` timestamp is older than 72 hours (stale protection — a catalogue that old may be missing scopes added without a git commit, e.g. from a worktree copy or a manual edit).

When falling back, record the fallback reason in the summary.

---

## Closed scope handling

Scopes with `status: closed` — whether discovered via a `closed/` subfolder or via a `status: closed` frontmatter value — are included in the output with `status: closed`.

Consumers of the catalogue apply the following rule: when resolving a `type/slug` reference for routing purposes, skip entries with `status: closed`. If the resolved entry is closed, treat the reference as if it were `[scope-not-found]` and fall back to `governance/feedback.md`. This prevents risk entries and other artefacts from being routed to an inbox that no one monitors.

The catalogue records closed scopes for auditability and for tools that need to know a scope exists but is no longer active (e.g. a migration tool checking whether a risk should be re-scoped).

---

## What is not prescribed

- **The frequency of scheduled runs.** Daily is typical (consistent with the main catalogue agent's cadence) but the adopter declares the schedule. The agent does not require a particular frequency.
- **Whether every structural folder must have a feedback.md.** The agent records `feedback_inbox: null` for scopes without one. The `feedback-inbox` capability governs whether a feedback.md is required; the scope registry agent reports what exists without enforcing the requirement.
- **Whether the scope registry agent is the only mechanism for generating scopes.yaml.** An adopter may generate it via a CI script or another tool as long as the output conforms to the schema. The agent is the reference implementation, not the only valid implementation.
- **Whether closed scopes are eventually removed from the catalogue.** An adopter may prune closed entries from the catalogue after a retention window by adding exclusion rules to the manifest extension. By default, closed entries are retained indefinitely.
- **The specific git configuration for the commit.** The commit uses whatever `git config user.name` and `git config user.email` are set in the runner environment. The adopter declares these in the workflow.

---

## Related

- [`../spec.md`](../spec.md) — the tooling capability; agent contracts (specification, security, implementation, observability) that this agent must satisfy.
- [`../agent/spec.md`](../agent/spec.md) — the agent standard; write scope declaration, security layers, implementation requirements, and invocation log format.
- [`../../scope-registry/spec.md`](../../scope-registry/spec.md) — the capability spec this agent implements; defines the `scopes.yaml` schema, scope reference format, and resolution contract for consumers.
- [`../catalogue/spec.md`](../catalogue/spec.md) — the main catalogue agent; sibling tool generating `specs.yaml`, `decisions.yaml`, and other sub-catalogues. `scopes.yaml` is a separate sub-catalogue, not part of the main catalogue's output.
- [`../../adoption-manifest/spec.md`](../../adoption-manifest/spec.md) — declares the structural type vocabulary and the manifest `owner` field used as the programme-scope lead.
- [`../../feedback-inbox/spec.md`](../../feedback-inbox/spec.md) — governs whether a `feedback.md` exists; this agent reads but does not create feedback inboxes.
- [`../../risk-at-scope/spec.md`](../../risk-at-scope/spec.md) — primary consumer of scope references; uses `type/slug` format resolved via this catalogue.
