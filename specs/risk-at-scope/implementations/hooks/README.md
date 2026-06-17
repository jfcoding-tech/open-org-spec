# Risk log hook — reference implementation

**Owner:** Javier Fernandez
**Status:** Active

A git pre-commit hook that validates staged risk record files against the
risk-at-scope inline log contract (Layer 2 of the two-layer commit-time
enforcement described in `open-org-spec/proposals/risk-inline-log.md`,
section 6).

This is a reference implementation. Adopters adapt the path pattern and
excluded-filename constants at the top of the script to match their
repository's conventions.

## What the hook checks

For each staged file matching `*/risks/<slug>.md` (excluding `README.md`):

1. **Required frontmatter fields** — `id`, `title`, `description`, `owner`,
   `status`, and `escalation_threshold` must all be present and non-empty.
2. **`## Log` section present** — the file body must contain a `## Log`
   heading.
3. **Log entry matches `disposition_at`** — if `disposition_at` is set in
   frontmatter, at least one `### <disposition_at value> —` heading must
   exist in the file.

If any check fails the hook prints a labelled error per violation and exits
non-zero, aborting the commit. The commit proceeds only when all staged risk
files pass all three checks (or when no risk files are staged).

**Scope boundary.** The hook validates risk record files only
(`*/risks/*.md`). The risk catalogue (`governance/catalogue/risks.yaml`) is
agent-generated on a separate automated stream and is explicitly excluded —
the hook never validates or blocks commits to the catalogue.

### Example output

```
RISK CONFORMANCE: functions/legal/risks/2026-05-01-ai-premium-framing.md
  [FAIL] missing required field: description
  [FAIL] ## Log section absent
  [FAIL] disposition_at 2026-06-17 has no matching ## Log entry

Commit aborted. Fix the conformance errors above and re-run git commit.
```

## How to install

### Option A — hooksPath (recommended for teams using Claude Code)

If your repository already sets `core.hooksPath` to `.claude/hooks`, copy
or symlink the script there and make it executable:

```bash
cp open-org-spec/specs/risk-at-scope/implementations/hooks/check-risk-log.sh \
   .claude/hooks/check-risk-log.sh
chmod +x .claude/hooks/check-risk-log.sh
```

Then ensure the hooksPath is configured:

```bash
git config core.hooksPath .claude/hooks
```

### Option B — symlink into `.git/hooks`

If you use the default `.git/hooks` directory:

```bash
chmod +x open-org-spec/specs/risk-at-scope/implementations/hooks/check-risk-log.sh
ln -s ../../open-org-spec/specs/risk-at-scope/implementations/hooks/check-risk-log.sh \
      .git/hooks/pre-commit
```

Adjust the relative path if your repository layout differs.

### Option C — copy and rename

Copy the script to `.git/hooks/pre-commit` (or append its body to an
existing pre-commit hook), make it executable, and commit the copy to your
repository so every contributor picks it up via `git pull`.

## Adapting for your repository

Two constants at the top of the script control path matching:

| Constant | Default | Purpose |
|---|---|---|
| `RISK_FILE_PATTERN` | `(^|/)risks/[^/]+\.md$` | grep -E pattern identifying risk record files by path |
| `EXCLUDED_NAMES` | `README.md` | Space-separated filenames to skip unconditionally |

Edit these if your convention uses a different directory name (e.g.
`risk-records/`) or if you need to exclude additional files.

## Enforcement layers

This hook is Layer 2 of a three-layer conformance strategy:

| Layer | When | Mechanism |
|---|---|---|
| 1 | Edit time | Claude Code pre-tool hook — blocks Write/Edit calls on risk files missing a log entry |
| 2 | Commit time | This hook — fires on `git commit` regardless of tool used |
| 3 | Daily | Risk scanner agent — reads `risks.yaml` and routes disposition requests to feedback inboxes |

Any one layer is sufficient to surface a gap. All three together mean
non-conformant risk files are caught at the earliest possible moment.

## Related

- [`../github-actions/spec.md`](../github-actions/spec.md) — GitHub Actions
  implementation for the registry and scanner agents
- [`../../spec.md`](../../spec.md) — risk-at-scope capability spec
- [`../../scanner.md`](../../scanner.md) — risk scanner agent (Layer 3)
- [`../../../../proposals/risk-inline-log.md`](../../../../proposals/risk-inline-log.md) — the proposal this implementation satisfies
