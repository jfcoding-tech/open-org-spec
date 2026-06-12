---
change: governance-protection-hook
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: governance protection hook

## Intent

Add a pre-commit hook template to the `governance-at-scope` capability. When installed, the hook blocks new files from being committed to a governed folder (`governance/`) by anyone whose git identity does not match the declared governance owner. The owner is read from the governed folder's `README.md` frontmatter — no hardcoding required. The hook is installed by `/adhere-to tooling` when `governance-at-scope` is active.

## Rationale

**Declaring governance ownership is not the same as enforcing it.** The `governance-at-scope` capability requires every governed folder to declare an owner in its `README.md` frontmatter. That declaration is a statement of intent. Without enforcement, it relies entirely on contributors reading the README and choosing to comply — a weak guarantee, especially as a repo grows and contributors arrive with less context.

**Violations happen at commit time, not at read time.** A contributor who adds content to the wrong folder does so when they commit. A pre-commit hook intercepts at exactly that moment — before the violation is in the history, before it has to be reverted, before the owner has to have a corrective conversation. The cost of blocking at commit time is one clear error message. The cost of catching it after is higher for everyone.

**The owner is already declared — the hook just reads it.** Every conformant `governance/README.md` carries a frontmatter `owner.name` field. A generic hook reads that field and compares it against `git config user.name`. No adopter-specific configuration is required beyond what the capability already mandates. The hook is a natural enforcement layer on top of an existing declaration.

**The distinction between added and modified files is structural.** The hook blocks new files (git status `A`) but not modifications to existing files (status `M` or `D`). This is intentional: the governance owner has already approved the existence of every file currently in `governance/`. Modifying an existing governance file is within the scope of any contributor who has legitimate reason to update it. Adding a *new* file is the gated action — it changes what governance covers, which is the governance owner's decision to make.

**A local hook is the friendly gate; CI is the authoritative gate.** Pre-commit hooks can be bypassed with `--no-verify`. The hook is not a hard security boundary — it is a friction point that catches accidental misrouting and surfaces the routing rules at the moment they are most actionable. A CI check (a GitHub Actions workflow that detects new files committed to `governance/` by non-owners) is the authoritative enforcement layer. Both are needed; neither alone is sufficient. This proposal covers the hook; CI enforcement is a companion addition.

**Validated in practice.** This hook was first implemented as a Busuu-specific script (`.claude/hooks/check-governance-additions.sh`) after a contributor added content directly to `governance/` without the governance owner's approval. The pattern is generic: any adopter with `governance-at-scope` active faces the same risk. The Busuu instance proved the mechanism works; this proposal extracts the generic core for the standard.

## Delta

Addition to the `governance-at-scope` capability: a new hook template at `specs/governance-at-scope/hooks/pre-commit.sh`.

The template is generic — no adopter-specific values. It reads the governance owner from the governed folder's `README.md` frontmatter at runtime.

**Hook behaviour:**

1. Inspect the git index for files with status `A` (added) under the governed folder path (default: `governance/`).
2. If no new files are staged under the governed path, exit 0 — nothing to check.
3. Read the governance owner name from `<governed-folder>/README.md` frontmatter (`owner.name`).
4. Compare against `git config user.name`.
5. If the committer matches the owner, exit 0.
6. If the committer does not match, print a structured error message and exit 2.

**Error message content:** the blocked file paths; the declared governance owner; the committer's identity; the routing decision tree (does this instruct how the repo works? → governed folder; is it function content? → functions/; is it a time-boxed initiative? → projects/; is it an observation? → feedback.md); a pointer to the governed folder's README for full routing rules.

**Installation:** `/adhere-to tooling` installs the hook template into the adopter's git hooks path (resolved from `git config core.hooksPath`, defaulting to `.git/hooks/`) as part of the `governance-at-scope` artefact set. The template call is appended to the pre-commit hook if one already exists, or written as a new pre-commit hook if none does. It is appended before any `exit 0` line, not after.

**The hook is added to the `governance-at-scope` artefacts block**, with:
- `type: file`
- `path: {{standard#git_hooks_dir}}/pre-commit` (appended, not overwritten)
- `check.type: file_contains` with the hook call signature

**Owner resolution.** The hook reads `owner.name` from the governed folder's README frontmatter using a lightweight YAML extraction (a `grep`/`sed` pattern, no `yq` dependency). If the field cannot be parsed, the hook skips rather than blocks — degrading gracefully rather than breaking commits for everyone.

## Acceptance scenarios

### Governance owner may always add files

Given a contributor whose `git config user.name` matches the `owner.name` in `governance/README.md`
When they stage a new file under `governance/` and commit
Then the hook exits 0 and the commit proceeds

### Non-owner adding a new file is blocked

Given a contributor whose `git config user.name` does not match the governance owner
When they stage a new file under `governance/` and commit
Then the hook exits 2 with a structured error message naming the blocked file, the declared owner, and the routing alternatives
And the commit does not proceed

### Modifying an existing governance file is never blocked

Given any contributor staging a modification (`M`) or deletion (`D`) to an existing file under `governance/`
When they commit
Then the hook exits 0 regardless of committer identity

### No new governance files — hook is silent

Given a commit with no files staged under `governance/`
When the pre-commit hook runs
Then the hook exits 0 immediately with no output

### owner.name cannot be parsed — hook degrades gracefully

Given a `governance/README.md` with a malformed or missing `owner.name` field
When the hook runs and fails to parse the owner
Then the hook exits 0 with a warning to stderr rather than blocking all commits
And the warning suggests checking the `governance/README.md` frontmatter

### /adhere-to tooling installs the hook

Given an adopter with `governance-at-scope` active
When `/adhere-to tooling` is run
Then the hook template is present in the adopter's git hooks path
And the pre-commit hook calls it before any `exit 0`

### Hook appends to existing pre-commit without overwriting

Given an adopter whose `.git/hooks/pre-commit` already contains another check (e.g. the drift-check sentinel)
When `/adhere-to tooling` installs the governance hook
Then the existing check is preserved
And the governance check is appended before the final `exit 0`

## Related

- `specs/governance-at-scope/spec.md` — the capability this hook enforces; ownership declaration is already required
- `specs/tooling/adhere-to/spec.md` — the tool that installs the hook artefact
- `specs/tooling/hooks/pre-commit.sh` — the existing pre-commit hook template (drift-check sentinel); the governance hook appends to this
