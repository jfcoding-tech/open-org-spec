---
change: risk-inline-log
status: closed
opened: 2026-06-17
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: inline change log for risk records

## Intent

Add a required `## Log` section to the risk record schema. Every time `status`, `disposition_at`, or `owner` changes, the author appends a dated entry to this section explaining what changed and why. The log is append-only and human-readable. The scanner validates that each `disposition_at` value has a matching log entry; records with a stale or missing log entry are flagged as conformance gaps.

## Rationale

**The standard tracks that a disposition happened, but not what was decided.** The `disposition_at` field records the date of the last disposition action. The `status` field records the outcome. Neither field carries a human-readable explanation. A reader looking at a risk one week after a review has no way to know what was concluded — only that something changed. This is the same gap that prompted decision records in governance: a date without reasoning is not a disposition, it is a timestamp.

**The "confirm with date" move produces a date with no record.** When an owner re-affirms a risk as still open, they update `disposition_at` and nothing else. This is valid per the standard. But it leaves no trace of why the risk was not deferred or closed — which is often the most important part of the decision. Over time, a risk with repeated `disposition_at` updates but no explanations looks identical to a risk that has never been reviewed.

**Terminal dispositions have the same gap.** `status: mitigated` records that the risk was resolved. The `disposition_decision_ref` field is recommended but not required, and points to an external document rather than containing the reasoning directly. For `status: closed`, only "an optional note" is mentioned — with no defined location or format. Readers of the risk file cannot tell what was done without following links that may not exist.

**Inline is the right place.** Decision records are the right home for full ADRs (accepted risks). For confirmations, deferrals, mitigations, and closures — the reasoning belongs in the risk file itself, not in a separate document. The risk file is the primary read surface; every disposition should be legible from it without navigating elsewhere.

**Append-only preserves history.** A risk that is confirmed open three times before being mitigated tells a story. The log section preserves that story in full. Overwriting a single field loses it.

**Enforcement requires the scanner to read file content.** This is a scope expansion for the scanner, which currently derives everything from the `risks.yaml` catalogue. The log validation step requires reading individual risk file bodies. This is an explicit design trade-off: log integrity checking is worth the additional read cost.

## Delta

Changes to the `risk-at-scope` capability.

### 1. New required section: `## Log`

Every risk file must contain a `## Log` section. The section is append-only. Each entry uses the following heading format (strict — machine-parseable):

```
### YYYY-MM-DD — <author name> — <change type>
```

`<change type>` is one of: `confirmed open` | `status changed to <value>` | `owner changed to <name>` | `disposition date updated`.

The entry body is free text: the author explains what they found, what they decided, and why. Minimum: one sentence. No maximum.

**Example:**

```markdown
## Log

### 2026-06-17 — Javier Fernandez — confirmed open
Still open. Enterprise position statement drafted and shared with legal counsel as
interim mitigation. Full buyer FAQ deferred to 2026-08-01. Not ready to move to
deferred status until Felix confirms the commercial team has what they need.

### 2026-06-12 — Javier Fernandez — confirmed open
Reviewed. No structural change. Watching for Felix's response on buyer questions
before moving to deferred.
```

### 2. Required log entry for every `disposition_at` change

When `disposition_at` changes (on any status transition or re-affirmation), a log entry dated the same day as the new `disposition_at` value is required. The scanner validates this match.

The strict heading format `### YYYY-MM-DD — ` makes the date machine-parseable without reading the body.

### 3. Owner changes require a log entry

Reassignment is a disposition move. When `owner` changes, a `### YYYY-MM-DD — <author> — owner changed to <new owner>` entry is required. This ensures every ownership handoff carries a reason.

**Multi-owner risks.** When a risk has multiple owners and any one of them writes a log entry, the entry is valid. The author is identified in the heading. No joint authorship or quorum is required.

### 4. Scanner changes

The scanner gains a new validation step (runs after the existing escalation step):

For each risk with `status` in `(open, in-progress, monitoring, mitigated, mitigated-with-conditions, deferred)`:

1. Read the risk file body.
2. Find the `## Log` section.
3. Parse heading dates: `### YYYY-MM-DD —` lines.
4. Check that at least one heading date matches `disposition_at` exactly.
5. If no match: write a `[log-missing]` disposition request to the owner's feedback inbox.
6. If `## Log` section is absent entirely: write a `[log-absent]` disposition request.

`closed` and `resolved` risks are exempt from ongoing validation — their log is frozen.

**Scanner read cost.** The scanner already walks `risks/` folders to build the catalogue. This step adds one file-read per active risk per daily run. At the current scale of ~42 risks, this is negligible.

### 5. `/new-risk` scaffolding change

`/new-risk` scaffolds the `## Log` section with the creation entry:

```markdown
## Log

### YYYY-MM-DD — <author> — status changed to open
Risk created.
```

### 6. Commit-time enforcement (two-layer)

Enforcement at commit time is a hard gate on conformance — it prevents a non-conformant risk file from entering the repository, closing the gap between a missing log entry and its detection. Two layers apply:

**Layer 1 — Claude Code pre-tool hook (edit-time).**
Fires on Write/Edit tool calls against any `*/risks/*.md` file. If `disposition_at` in the frontmatter is set and no `## Log` entry dated that day exists in the file being written, Claude Code blocks the write and surfaces a prompt: "This risk file has no log entry for `disposition_at: <date>`. Add a `### <date> — <author> — <change type>` entry before saving." The author resolves it inline before the write proceeds.

**Layer 2 — git pre-commit hook (commit-time).**
A shell script committed to the adopter repository at a conventional path (e.g., `.claude/hooks/check-risk-log.sh`) is installed as a git pre-commit hook. It fires on every `git commit`, regardless of tool. The hook has a single responsibility: **if a staged file lives inside a `risks/` directory, validate it conforms to the risk record spec.**

For each staged file matching `risks/[^/]*\.md$` (at any depth, excluding `README.md`):

1. **Required frontmatter fields** — verify `id`, `title`, `description`, `owner`, `status`, and `escalation_threshold` are present and non-empty.
2. **`## Log` section present** — verify the file body contains a `## Log` section.
3. **Log entry matches `disposition_at`** — if `disposition_at` is set, verify at least one `### <disposition_at> —` heading exists in the `## Log` section.

If any check fails: print a specific error per violation and exit non-zero, aborting the commit. Examples:

```
RISK CONFORMANCE: functions/legal/risks/2026-05-01-ai-premium-framing.md
  [FAIL] missing required field: description
  [FAIL] ## Log section absent
  [FAIL] disposition_at 2026-06-17 has no matching ## Log entry
```

The hook passes when all staged risk files pass all three checks, or when no risk files are staged.

**Scope boundary.** The hook validates risk record files only (`*/risks/*.md`). The risk catalogue (`governance/catalogue/risks.yaml`) is agent-generated on a separate automated stream and is explicitly out of scope — the hook must not validate or block commits to the catalogue.

**Reference implementation contract.** The adopter provides the script; the standard specifies the contract above. A reference implementation is provided in `open-org-spec/specs/risk-at-scope/implementations/` for adopters to adapt.

**Layer precedence.** Layer 1 catches the gap at edit time (fastest feedback). Layer 2 catches anything that bypassed Layer 1 — direct file edits, Obsidian edits, or manual git staging. The scanner (daily) catches anything that bypassed both layers. Three independent checkpoints; any one is sufficient to surface the gap.

### 7. Backfill for existing risk files

Existing risk files do not have a `## Log` section. A one-time backfill is required before scanner enforcement and the git hook are activated.

**Handling existing informal sections.** Several section names have been used informally in existing risk files and carry content that belongs in `## Log`:

| Existing section | Treatment |
|---|---|
| `## Resolution` | Convert to a `## Log` entry dated from git history. Content preserved verbatim as the entry body. Original heading removed. |
| `## Updates` | Convert each update paragraph to a separate `## Log` entry where a date can be inferred; otherwise one combined entry. Original heading removed. |
| `## Disposition (...)` | Convert to a `## Log` entry; date extracted from the heading (e.g., `## Disposition (Sam, 2026-06-15)` → `### 2026-06-15 — Sam — status changed to mitigated`). Content preserved verbatim. Original heading removed. |
| `## Mitigation` | Not converted — describes the ongoing mitigation approach, not a timestamped decision. Remains as-is alongside `## Log`. |

**Backfill approach for all other files:**
- For each existing risk file without an informal section, check git log for the date each field was last modified.
- Reconstruct a log entry: `### <git date> — <git author> — <inferred change type>`.
- Body: `Pre-log entry reconstructed from git history. No reason recorded at the time.`
- For fields with no git history: use `created_at` as the date.

**Activation sequence.** Backfill first, then activate scanner enforcement and install the git hook. The two steps are committed separately so the backfill is auditable independently of the enforcement activation.

## Acceptance scenarios

### Owner confirms open — log entry required

Given a risk with `status: open` and `disposition_at: 2026-06-12`
When the owner updates `disposition_at` to `2026-06-17` without adding a log entry
And the scanner runs
Then a `[log-missing]` disposition request is written to the owner's feedback inbox
And the entry states: "disposition_at updated to 2026-06-17 but no ## Log entry found for that date"

### Owner confirms open with log entry — no escalation

Given a risk with `disposition_at: 2026-06-17`
And the risk file contains `### 2026-06-17 — Javier Fernandez — confirmed open` with a body
When the scanner runs
Then no `[log-missing]` entry is written
And the risk is considered current

### Risk file without ## Log section — flagged

Given a risk file with no `## Log` section
When the scanner runs
Then a `[log-absent]` disposition request is written to the owner's feedback inbox

### Status changed to mitigated — log entry required

Given a risk where `status` is changed from `open` to `mitigated`
And `disposition_at` is set to today
When the owner commits without a log entry dated today
And the scanner runs
Then a `[log-missing]` entry is written

### Owner changed — log entry required

Given a risk where `owner` changes from person A to person B
And `disposition_at` is updated
When the scanner runs and no log entry for that date exists
Then a `[log-missing]` entry is written to the new owner's feedback inbox

### Backfill entry is valid

Given a risk file containing a log entry with body "Pre-log entry reconstructed from git history. No reason recorded at the time."
When the scanner runs
Then the entry is treated as a valid log entry
And no `[log-missing]` escalation is raised for dates covered by the backfill

### /new-risk scaffolds the Log section

Given a contributor runs `/new-risk`
When the file is created
Then it contains a `## Log` section with one entry dated today and body "Risk created."

### Git hook blocks a non-conformant commit

Given a contributor edits a risk file directly (not via Claude Code) and updates `disposition_at` to today
And adds no `## Log` entry
When the contributor runs `git commit`
Then the git pre-commit hook exits non-zero
And prints: "RISK LOG MISSING: <filepath> — disposition_at <date> has no matching ## Log entry"
And the commit is aborted

### Existing ## Resolution section is absorbed on backfill

Given a risk file with a `## Resolution` section containing closure reasoning
When the backfill runs
Then the `## Resolution` content is preserved as a `## Log` entry body
And the `## Resolution` heading is removed
And the `## Log` entry is dated from git history for that file

### Existing ## Mitigation section is preserved on backfill

Given a risk file with a `## Mitigation` section
When the backfill runs
Then the `## Mitigation` section is unchanged
And a separate `## Log` section is added alongside it

## Out of scope

- **Log entry content validation.** The scanner checks that a log entry exists for the matching date. It does not validate the quality or completeness of the entry body. Content is the author's responsibility.
- **Retroactive log entries.** Once committed, log entries are not edited. If an entry was wrong, a new entry explains the correction.
- **Log entry for `closed` risks.** The final log entry (the closure reason) is required. No further entries are required after `status: closed`.
