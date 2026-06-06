# Adhere-to

A tool of the open-org-spec tooling capability. Scans an adopter's repository against a named capability's rules, surfaces gaps as feedback entries addressed to the affected owners, and wires up the capability's commands. Invoked once at activation, re-run on demand when the repo or capability evolves.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** none yet (the first adopter reference will be the first; manual conformance passes have approximated the behaviour).

## Purpose

A capability declared `active` in the adoption manifest carries rules that the adopter has committed to. Some of those rules will already be satisfied — the adopter activated the capability because the patterns already exist in the repo. Some will not be — pre-existing content does not conform, or the capability's edge cases were missed.

Without a conformance pass, an adopter activates the capability and immediately ships drift: the manifest says the rules apply, but the repo has known gaps that no one has flagged. The adopter then either re-derives gaps manually each time they edit, or accepts silent non-conformance.

The `adhere-to` tool brings the repo and the manifest into agreement: it walks the affected areas, lists every gap, and routes each one to the person responsible. The adopter then either conforms or accepts each gap as a known follow-up recorded in the manifest. The tool does not unilaterally edit content — it surfaces work for the affected owners to do.

## Pattern

### Inputs

- **Capability slug** — required. The capability to check (must be declared `active` or `proposed` in the manifest).
- **Target** — optional. A single instance to scope the scan to (a slug or path), instead of every affected area. Useful when a contributor wants to validate their own folder before flipping status, rather than running the full sweep.
- **Mode** — optional. One of `full` (default — check every affected area), `subset` (limit to paths matching a glob or scope), `fix-with-me` (interactive — walk each gap with the contributor and offer inline fixes before falling through to default routing; see Step 2a), or `dry-run` (compute gaps but do not open feedback entries or wire commands; only surface the summary).

### Step 0 — Verify state

Read the manifest at `.open-org-spec/config.yaml`. Verify:
- The manifest exists. Refuse if not — redirect to `oos:adopt-manifest`.
- The named capability is declared. Refuse if not — redirect to `oos:adopt-<capability>` (per-capability activation).
- The capability's status is `active` or `proposed`. Refuse if `inactive` — there is nothing to adhere to.

Then read the capability spec at `open-org-spec/specs/<capability>/spec.md`. If the manifest declares an `extension` for the capability, read that too. If the manifest declares `tool_extensions` for the capability, read each of those alongside the corresponding tool spec under `open-org-spec/specs/<capability>/<tool>/spec.md`. Base capability + capability extension + tool specs + tool extensions form the effective rules for this adopter.

If `open-org-spec/specs/adherence-check/spec.md` declares a `#### Against <capability>` section for the named capability, read those check rules too — they are the mechanical translation of the capability's rules into findings the tool produces.

### Step 1 — Determine the scope of affect

Every capability spec declares which areas of an adopter's repo it governs — sometimes explicitly in a "What this capability governs" section, sometimes implicit in the file-location conventions defined in the Pattern section. The tool reads the capability to enumerate the affected areas:

- **File-shape capabilities** (e.g. `people`) — govern files matching a path pattern. Example: every `<scope>/people.md`.
- **Folder-structure capabilities** (e.g. `project`, `governance-at-scope`) — govern folders matching a path pattern. Example: every `projects/<slug>/`.
- **Cross-cutting capabilities** (e.g. `feedback-inbox`) — govern any file matching a pattern across many scopes. Example: every `<scope>/feedback.md`.

For each affected area, the tool produces a path list. The list is the surface to be checked.

### Step 2 — Check conformance

For each affected path, apply the capability's rules. Conformance checks vary by capability — frontmatter presence, required sections, closed vocabulary membership, structural shape — but the output is uniform: a list of **gaps**, where each gap names a path, the rule it violates, and the owner of the affected area.

The owner is inferred from the affected file or its enclosing scope. Most capabilities define ownership headers (`Owner:`, role tables in `people.md`, the manifest's `owner` field) that the tool reads to identify who is responsible. If no owner can be inferred for a gap, the tool falls back to the manifest owner.

**Inbox-routing fallback.** Each gap routes to the inbox closest to the affected file, per the `feedback-inbox` capability's conventions. If the affected file lives in a scope that has no `feedback.md` (typical for manifest-level files like the commands README, or `.open-org-spec/` configuration files), the gap routes to the manifest owner's inbox — either `<adopter-root>/feedback.md` if one exists, or the most prominent inbox addressed to the manifest owner (for example, a shared module's `feedback.md` addressed to the manifest owner; an equivalent exists in any conformant repo where the manifest owner participates).

Gaps the tool produces should be specific and actionable. *"The people.md is non-conformant"* is not enough. *"`clusters/governance/people.md` is missing — three role specs declare current holders but no people.md exists at the scope; the manifest's `people` capability requires one"* is.

### Step 2a — Fix-with-me flow (when mode = `fix-with-me`)

Activates an interactive flow before Step 3's default feedback routing. For each gap, the tool offers the contributor an inline fix; gaps not fixed here fall through to Step 3 as usual.

**Authority precondition.** Fix-with-me writes to files. The tool only enters the interactive flow for gaps in files the running contributor owns (per the affected file's role header, the nearest `people.md`, or the manifest's `owner` field). Gaps in files owned by someone else skip the prompt and route to that owner's inbox per Step 3 — fix-with-me does not bypass ownership.

**Per-gap loop.**

1. **Surface the gap.** Path, rule citation, what was expected, what was found, one-sentence rationale.
2. **Classify.**
   - *Mechanical* — missing required field, missing required prose section, `TBD` value, missing extension-declared field. Eligible for fix-with-me.
   - *Human judgement* — the kind a capability explicitly puts outside v0 scope (e.g., the requester-as-owner alignment for the `project` capability). Not eligible. Route to feedback and continue.
3. **Prompt** (mechanical gaps only). Ask the contributor for the missing content. They may provide it, skip, or ask to route to feedback instead.
4. **Preview before write.** Show the proposed edit as a single atomic block — file path, the lines to add or change for the content fix, *and* the `tooling` stamp update for `oos:adhere-to` (see [Stamping](#stamping) below). Wait for explicit confirmation. Write all of it on confirmation; otherwise treat as skip.
5. **Skip semantics.** A skipped gap is a deferral, not a decline. Skipped gaps fall through to Step 3 and route to the owner's inbox as usual.

**Scope of write.** The tool writes to the working tree only. It does not stage, commit, or push. The contributor reviews working-tree state at the end and decides when to save (e.g., via the adopter's `oos:update` equivalent).

**Manifest-locked files.** Files under `.open-org-spec/` are governed by the manifest owner regardless of who runs the tool. Fix-with-me refuses to write to those paths unless the contributor *is* the manifest owner; otherwise routes to feedback addressed to the manifest owner.

### Stamping

`adhere-to` stamps every file it writes to. The stamp is part of the same atomic write as the content fix, per Step 2a's *Preview before write*.

When `fix-with-me` writes a fix to a file:

- If the file's `tooling` block has no `oos:adhere-to` entry yet, add one with today's date as `first`, today's date as `last` (when not equal), and the running contributor's `git config user.name` as `by`.
- If an entry already exists, update only `last` and `by`; `first` is the recorded first-use and does not change.
- If the host capability does not define a tooling block (the standard's `tooling` field is currently declared by the `project` capability; other capabilities adopt it as they evolve), stamping is skipped without error — the write proceeds without a stamp, and a `warning` is recorded in Step 5's summary.

The stamp is **not optional** for capabilities that declare a tooling block. A write without a stamp emits a `warning` finding on the next `adhere-to` run, per the [tool stamping principle](../spec.md#tool-stamping-state-changing-tools) at the parent tooling capability.

`adhere-to` in `dry-run`, `full`, or `subset` mode does not write to files; no stamping happens. Stamping is `fix-with-me` only.

### Step 3 — Route gaps to owners (default mode; fallback for fix-with-me)

*In `fix-with-me` mode, gaps that were fixed inline at Step 2a do not reach this step. Gaps that were skipped, declined, judged outside fix-with-me's eligibility, or affect a file the running contributor doesn't own all fall through here as if mode were `full`.*

For each gap, open a feedback entry addressed to the gap's owner in the appropriate scope's inbox. The inbox follows the `feedback-inbox` capability's conventions:

- For a gap in `<scope>/people.md`, open the entry in `<scope>/feedback.md` (or the nearest inbox if the scope has none).
- For a gap in `projects/<slug>/spec.md`, open the entry in `projects/<slug>/feedback.md`.
- For a gap in a cross-cutting file (e.g., `CLAUDE.md`), open the entry in the manifest-owner-addressed inbox.

The entry follows the substantive-observation format defined by `feedback-inbox` — Observation, Why this matters, Suggested direction, Ask. The Ask is concrete: "conform, push back, or accept as a known follow-up recorded in the manifest's `note` field for this capability."

**Idempotence.** Re-runs of `adhere-to` should not duplicate entries. The tool checks the affected inbox for an existing entry referencing the same gap (matched by path + rule). If found and unresolved, skip. If found and resolved but the gap persists, re-open with a note pointing at the prior entry.

### Step 4 — Scaffold artefacts

Every capability spec may declare an `## Artefacts` section containing a fenced YAML block. This block is the canonical, machine-readable declaration of what physical artefacts a conformant adopter repo must contain. `adhere-to` reads this block and scaffolds any missing or non-conformant artefacts.

#### Artefact schema

```yaml
artefacts:
  - id: <unique slug within this capability>
    type: file | gitignore_entry | directory
    path: <path in the adopter repo>                            # supports {{variable_name}}
    template: <path in open-org-spec, relative to repo root>   # type: file only
    variables:                                                  # optional; apply to path, template content, and check.value
      - name: <variable_name>                                   # referenced as {{variable_name}}
        source: config.yaml#<dotted.path>                       # read from adoption manifest
                | git_config#<key>                              # read from git config
                | standard#manifest_dir                        # directory containing config.yaml
                | standard#git_hooks_dir                       # git config core.hooksPath, defaulting to .git/hooks
    check:
      type: file_exists | file_executable | file_contains | directory_exists | gitignore_entry
      value: <string>                                           # supports {{variable_name}}; required for file_contains and gitignore_entry
    condition:                                                  # optional — skip artefact if condition is false
      type: config_equals | scan_frontmatter
      # config_equals: check a config.yaml field
      config_path: <dotted.path in config.yaml>                # config_equals only
      equals: <value>                                           # config_equals only
      # scan_frontmatter: check whether any file in a directory has a frontmatter field
      directory: standard#adopter_command_dir                  # scan_frontmatter only
      frontmatter_field: <field name>                          # scan_frontmatter only
```

**Standard variable sources:**

| Source | Resolves to |
|---|---|
| `standard#manifest_dir` | Directory containing `config.yaml` (e.g. `.open-org-spec`) |
| `standard#git_hooks_dir` | `git config core.hooksPath`, defaulting to `.git/hooks` if unset |
| `standard#adopter_command_dir` | The adopter's command directory for the active LLM interface (e.g. `.claude/commands` for Claude Code) |

**Variable substitution** applies to `path`, template file content, and `check.value` — wherever `{{variable_name}}` appears.

#### How `adhere-to` processes artefacts

For each entry in the `artefacts` block:

1. **Resolve variables.** Resolve all declared variables by reading their `source`. Substitute `{{variable_name}}` in `path`, template content, and `check.value`.
2. **Evaluate condition.** If a `condition` is declared:
   - `config_equals` — read the value at `config_path` in `config.yaml`. Skip if it does not equal `equals`.
   - `scan_frontmatter` — scan files in `directory` for any file containing `frontmatter_field` in its frontmatter. Skip the artefact if none found.
3. **Check.** Apply the `check` rule against the adopter repo. If the check passes, the artefact is conformant — skip.
4. **Scaffold.** If the check fails:
   - `type: file` — write the template (with variable substitution) to `path`. After writing: if `check.type` is `file_executable`, set executable permission (`chmod +x` on Unix). On Windows, note that executable permission does not apply but git will invoke the hook via its bundled bash regardless.
   - `type: gitignore_entry` — append the resolved `check.value` to `.gitignore` if not present.
   - `type: directory` — create the directory at `path` if absent.
5. **Report.** Include scaffolded artefacts in the Step 5 summary.

#### Command relay scaffolding (subset of artefacts)

Command relays are a specialised artefact type handled by the existing relay convention. On first activation (the manifest's `activated` date matches today's date, or no relays exist in the adopter's command directory for this capability):

- For each command file the capability declares (`adopt.md`, `new.md`, `extend.md`, or other `<verb>.md`), create a relay at the adopter's command path (e.g. `.claude/commands/<command-name>.md`).
- Add a row to the adopter's commands README under "Standard commands (from active capabilities)" linking the relay to the canonical command spec.

Subsequent runs skip relay creation — relays already exist. Re-wiring after a capability change is a manual operation by the manifest owner.

**Authority.** All artefact scaffolding (files, gitignore entries, directories, relays, README updates) is a mechanical operation within the manifest owner's governance scope. `adhere-to` proceeds without per-file confirmation when invoked by the manifest owner. This is the deliberate exception to the tool's general principle of not modifying files unilaterally — artefacts are derived from the capability spec, which the manifest owner has activated.

### Step 5 — Surface summary

At the end of the run, the tool produces a single summary to the adopter:

- **Capability**: which capability was checked, at what manifest status.
- **Affected areas**: N paths scanned.
- **Gaps**: N gaps identified, broken down by owner and severity if the capability defines severities.
- **Feedback entries**: N opened (with paths), 0 duplicates skipped.
- **Artefacts scaffolded**: N files/entries created or fixed, broken down by artefact id. Or "skipped (all conformant)".
- **Commands wired**: N relays created on first activation, or "skipped (already wired)".
- **Fixed inline** (fix-with-me only): N gaps written to the working tree, with affected paths. Reviewer should inspect working-tree state before saving.
- **Next steps**: each owner reviews the entries in their inbox; the manifest owner reviews the summary and either lets the adoption proceed or accepts gaps as recorded follow-ups in the manifest's `note` field.

The summary is what `oos:adopt-<capability>` shows after activation. It is also what `adhere-to` returns on every re-run.

### Extension points

Adopters extend the generic pattern with org-specific context:

- **Ownership-resolution rules** — adopters may add their own conventions for inferring gap owners (e.g., a cluster-level fallback when a file has no `Owner:` header).
- **Severity model** — adopters may classify gaps as `blocker / warning / info` and only open feedback entries for blockers, while logging warnings and info-level gaps to the summary.
- **Routing overrides** — adopters may redirect specific gaps to a different inbox than the default (e.g., cross-cluster gaps always go to a central inbox).
- **Skip rules** — adopters may declare certain paths exempt from a capability (legacy areas, third-party content), recorded in the manifest's `note` field with rationale.

## What is not prescribed

- **The specific check implementation for each capability.** Each capability spec is responsible for declaring its own conformance rules in a form the tool can check. The tool generalises the scan/compare/route loop; it does not embed per-capability check logic.
- **Whether `adhere-to` is invoked manually or by another command.** `oos:adopt-<capability>` may invoke it as the final step of activation; the adopter may also invoke it directly on demand. Both are valid.
- **Frequency of re-runs.** Once at activation is required. Adopters may set up scheduled re-runs (e.g., a weekly CI job) or run on demand; the standard does not require a frequency.
- **Whether resolved feedback entries are archived.** Adopters keep them inline per the `feedback-inbox` convention; archival is an adopter choice.

## Rationale

The activation-without-conformance gap is the primary risk of an adoption manifest: a capability declared `active` whose rules are silently violated across the repo undermines the manifest's value. `adhere-to` closes the gap by making activation produce a visible work list.

The choice to route via feedback entries rather than unilaterally edit files is structural. Editing files unilaterally would assume the tool knows what each owner intends; it does not. Feedback entries put the decision back with the owner, with the gap fully specified so they can act efficiently. The cost is a heavier inbox; the benefit is correctness and trust.

The first-run-only wiring of commands keeps re-runs cheap. Re-running `adhere-to` to recheck conformance does not re-scaffold relays already in place — the adopter's command directory is treated as stable state, not regenerated.

## Adoption

*(An `oos:adopt-adhere-to` command is not needed — this tool is invoked under the adoption-manifest capability's lifecycle, not adopted independently. Adopters get `adhere-to` automatically when they activate the `adoption-manifest` capability and run `oos:adopt-manifest`.)*

## Related

- [`../spec.md`](../spec.md) — parent tooling capability.
- [`../../adoption-manifest/spec.md`](../../adoption-manifest/spec.md) — the capability that defines when `adhere-to` runs and what it produces.
- [`../../adoption-manifest/adopt.md`](../../adoption-manifest/adopt.md) — first-time scaffolding of the manifest; sets up the manifest that `adhere-to` reads.
- [`../../feedback-inbox/spec.md`](../../feedback-inbox/spec.md) — the inbox conventions `adhere-to` uses to route gaps to owners.
- [`../catchup/spec.md`](../catchup/spec.md) — sibling tool; `catchup` surfaces what changed, `adhere-to` surfaces what does not conform.

## Flow diagram

The diagram below illustrates a fix-with-me run against the `project` capability. Two blocks: the outer step sequence (Step 0 → Step 5) and the per-gap loop that Step 2a expands.

```
═══════════════════════════════════════════════════════════════════
  OUTER FLOW
═══════════════════════════════════════════════════════════════════

  Contributor invokes:
  /adhere-to project <slug> --mode=fix-with-me
                            │
                            ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 0  Verify state                                       │
  │         read manifest + capability spec + check rules      │
  └────────────────────────────┬───────────────────────────────┘
                               ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 1  Enumerate affected paths                           │
  │         e.g. projects/<slug>/                              │
  └────────────────────────────┬───────────────────────────────┘
                               ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 2  Apply checks per "#### Against <capability>" rules │
  │         produces a gaps list                               │
  └────────────────────────────┬───────────────────────────────┘
                               ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 2a For each gap → run PER-GAP LOOP (below)            │
  └────────────────────────────┬───────────────────────────────┘
                               ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 3  Open feedback entries (routed gaps only)           │
  └────────────────────────────┬───────────────────────────────┘
                               ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 4  Wire commands (first activation only)              │
  └────────────────────────────┬───────────────────────────────┘
                               ▼
  ┌────────────────────────────────────────────────────────────┐
  │ Step 5  Summary                                            │
  │         N fixed inline · N routed to feedback              │
  └────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════
  PER-GAP LOOP (Step 2a)
═══════════════════════════════════════════════════════════════════

  one gap from gaps list
       │
       ▼
  ╔════════════════════════╗
  ║ Gate 1: Authority      ║                 ┌──────────────────┐
  ║ Am I the file owner?   ║─── no ─────────►│                  │
  ╚════════════════════════╝                 │  ROUTE           │
       │ yes                                 │                  │
       ▼                                     │  open feedback   │
  ╔════════════════════════╗                 │  entry in        │
  ║ Gate 2: Classification ║                 │  owner's inbox   │
  ║ Mechanical?            ║── judgement ───►│                  │
  ╚════════════════════════╝                 │  (defer to       │
       │ mechanical                          │   Step 3)        │
       ▼                                     │                  │
  ╔════════════════════════╗                 │                  │
  ║ Gate 3: Provide        ║                 │                  │
  ║ Did contributor give   ║─── skip ───────►│                  │
  ║ content?               ║                 │                  │
  ╚════════════════════════╝                 │                  │
       │ yes                                 │                  │
       ▼                                     │                  │
  ┌────────────────────────┐                 │                  │
  │ Preview edit           │                 │                  │
  │ path + diff lines      │                 │                  │
  └────────────┬───────────┘                 │                  │
               ▼                             │                  │
  ╔════════════════════════╗                 │                  │
  ║ Gate 4: Confirm        ║─── no ─────────►│                  │
  ║ Edit looks right?      ║                 │                  │
  ╚════════════════════════╝                 └─────────┬────────┘
       │ yes                                           │
       ▼                                               │
  ┌────────────────────────┐                           │
  │ WRITE to working tree  │                           │
  │ no commit, no push     │                           │
  └────────────┬───────────┘                           │
               │                                       │
               └───────────────────┬───────────────────┘
                                   ▼
                          next gap or exit loop
```

**Key invariants the diagram makes visible.**

- A gap reaches `WRITE` only by passing all four gates in sequence. Any "no" diverts to `ROUTE`, which is just deferred entry into Step 3.
- `ROUTE` is one destination, not four. Four failure paths converge there because there are four ways to land in feedback: not the owner, requires judgement, contributor skipped, contributor declined the preview.
- The loop is per-gap, not per-file. A single project spec producing four gaps means four passes through the gates, each with its own outcome.
- Step 3 still runs on a fix-with-me pass — it just operates on the smaller routed-gaps set. Step 5's summary surfaces both counts side by side.
