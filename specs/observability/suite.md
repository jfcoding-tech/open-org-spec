# Observability Suite

**Owner:** Javier Fernandez
**Status:** Active

An optional execution mode for the observability capability. When activated, the adopter's observability tools run as a scheduled automated suite — unattended, on a cadence — rather than only on-demand.

This is a **Case B standard capability agent** per the [`agent` spec](../tooling/agent/spec.md#contract-1--specification): the tools are already defined in `open-org-spec/specs/observability/`; no project spec is required. The adopter activates the suite by declaring it in their manifest and running `/oos:activate-observability-suite`.

---

## When to use

Activate the suite when the observability outputs should be refreshed automatically — so contributors always find a current picture when they open the repo — rather than only when someone runs a command manually.

Pull-based and scheduled execution are complementary. Scheduled runs keep outputs current between manual invocations; manual invocations can always be triggered on demand outside the schedule.

---

## The suite

The five standard observability tools run sequentially in a single automated execution:

| Tool | What it produces |
|---|---|
| `/owner-health` | Who owns what across all scopes |
| `/inbox-health` | Open feedback inbox state across all scopes |
| `/decision-health` | Decision record health and linkage |
| `/contributor-activity` | Contributor engagement over time |
| `/spec-activity` | Which specs are lived-in vs. abandoned |

All tools write to the adopter's declared observability output path. One execution = one commit with all five outputs refreshed.

---

## Contracts

The suite satisfies the `agent` capability's four contracts at the **suite level**, not per-tool:

### Contract 1 — Specification (Case B)

No project spec required. The specification is this document. The write scope declaration lives in the adopter's manifest or extension spec under `capabilities.observability.suite.write_scope`.

### Contract 2 — Security

#### Layer 1 — Write scope validator

Post-execution shell step. Diffs `git diff --name-only` against the adopter's declared observability output path. Any file written outside that path is reverted and the step exits with code 1:

```bash
UNEXPECTED=$(git diff --name-only | grep -vE '<observability-output-path>' || true)
if [ -n "$UNEXPECTED" ]; then
  echo "SECURITY: observability-suite wrote to unexpected files:"
  echo "$UNEXPECTED"
  git checkout -- $UNEXPECTED
  exit 1
fi
```

#### Layer 2 — Checkout scope

The suite requires broad read access (it scans the full org). The checkout must include all adopter-declared spec paths plus the observability output path. Sparse checkout to "only what the agent writes" is not practical here — include all governed scopes declared in the extension.

#### Layer 3 — Prompt guardrails

Injected before each tool's prompt:

```
WRITE SCOPE: you may only write to <observability-output-path>.
Any write outside this scope is a violation — stop and report it.

NO FABRICATION: extract values only from the files you read.
Do not infer, guess, or generate content not present in the repo.

EXIT ON UNCERTAINTY: if unsure whether an action is within scope,
append a one-line warning to <warnings-file> and stop.
```

### Contract 3 — Implementation

The suite is implemented as a single GitHub Actions workflow (or equivalent scheduled mechanism). Requirements:

- All five tools run sequentially in one job
- Write scope validator runs after all five tools complete, before the commit
- One commit covers all five tools' outputs
- Retry contract: `git pull --rebase` before each push attempt; max 3 attempts; 30s delay
- Manual trigger (`workflow_dispatch`) for on-demand runs outside the schedule
- Job timeout: `timeout-minutes: 60`

### Contract 4 — Observability

Each tool appends its own invocation log entry per the observability capability's standard format. The suite execution is visible in the invocation log as five sequential entries on the same timestamp.

---

## Extension points

| Extension point | Description | Default |
|---|---|---|
| Schedule | When the suite runs | *(required)* |
| Implementation | `github-actions` or `claude-code` | *(required)* |
| Write scope | The observability output path the suite may write to | *(required, from capability extension)* |
| Warnings file | Where uncertainty warnings are written | *(required, from capability extension)* |
| Tool sequence | Which tools to include and in what order | All five, in the order above |

---

## Activation

Run `/oos:activate-observability-suite` after setting `capabilities.observability.suite.status: active` in the adoption manifest. The command wires the scheduled execution (creates GitHub Actions workflows or `CronCreate` entries) and verifies the write scope and output path are declared.

---

## Related

- [`spec.md`](./spec.md) — observability capability; pull-based execution mode
- [`../tooling/agent/spec.md`](../tooling/agent/spec.md) — agent contracts; this suite satisfies them at the suite level (Case B)
- [`../tooling/spec-health/spec.md`](../tooling/spec-health/spec.md) — reference suite implementation
