# Risk-at-Scope: GitHub Actions Implementation

**Owner:** Javier Fernandez
**Status:** Active

The GitHub Actions runtime implementation for the `risk-at-scope` agents — the risk
registry agent ([`registry.md`](../../registry.md)) and the risk scanner agent
([`scanner.md`](../../scanner.md)). Satisfies the four agent contracts
([`../../../tooling/agent/spec.md`](../../../tooling/agent/spec.md)) using GitHub Actions
workflows and a model API. Concrete workflow structure and shell mechanisms are described
here; they are absent from the capability specs.

This is the risk-at-scope analogue of the spec-health GHA implementation
([`../../../tooling/spec-health/implementations/github-actions/spec.md`](../../../tooling/spec-health/implementations/github-actions/spec.md)),
and follows the same shared-contract structure.

## Combined workflow pattern

The registry and scanner agents run as **sequential steps in a single workflow file**
(the `risk-monitor` workflow), not as two separate workflows.

```yaml
# .github/workflows/risk-monitor.yml
on:
  schedule:
    - cron: '<adopter-declared schedule>'
  workflow_dispatch:
steps:
  - name: Run /risk-registry
    run: |
      # ... walk risks/ folders, write registry, commit, push
  - name: Run /risk-scanner
    run: |
      git pull --ff-only || true   # pick up the registry commit
      # ... read fresh registry, route disposition requests, commit, push
```

**Why combined, not separate.** The scanner reads the registry the registry agent
produces — it is a hard data dependency, not a soft timing preference. The scanner spec
refuses to run against a registry generated more than 25 hours ago. Running the two as
separate cron-scheduled workflows reintroduces the exact timing risk the scanner guards
against: if the registry workflow is delayed, queued, or fails silently, the scanner
either runs against a stale registry or skips. Sequencing them as steps in one workflow
makes the dependency explicit — the registry step commits first, the scanner step does
`git pull --ff-only` and then reads the fresh registry from the working tree. The scanner
cannot start before the registry has committed, and it always reads the current run's
output. This eliminates the timing risk entirely.

The single-workflow tradeoff (a registry failure blocks the scanner) is acceptable and
correct here: a scanner run against a missing or stale registry is worse than no scanner
run at all, because it produces incorrect escalations.

Each step sets the same `git config user.name` (`risk-monitor`) before running; the two
commit messages distinguish the agents (`chore: risk-registry update — …` and
`chore: risk-scanner nudges — …`), so the write-scope validator can scope its check to
the workflow's author while still attributing each commit.

## Write scope per agent

The two agents have different, non-overlapping write scopes. Each is enforced
independently by Layer 1 (write-scope validator) and Layer 2 (sparse checkout).

| Agent | Write scope |
|---|---|
| registry | `{{registry_path}}` (e.g. `governance/catalogue/risks.yaml`), `{{delta_log}}`, `{{invocation_log}}` |
| scanner | any `feedback.md` file within the declared scope tree, `{{invocation_log}}`, `{{warnings_file}}` |

The registry agent never writes a `feedback.md`; the scanner agent never writes the
registry or the delta log. The combined workflow validates both scopes against the
single `risk-monitor` author after both steps have committed.

## Sparse checkout requirements

Each agent checks out only the paths it legitimately reads and writes (Contract 2,
Layer 2). The combined workflow uses a single checkout step covering the union of both
agents' paths, because both run in the same job.

**Registry agent reads:**
- `{{scope_risk_paths}}` — every `risks/` folder across the declared scope tree
- `{{registry_path}}` — the existing registry (for delta merge)
- `{{invocation_log}}` — to find the last successful run timestamp (delta gate)

**Registry agent writes:**
- `{{registry_path}}`, `{{delta_log}}`, `{{invocation_log}}`

**Scanner agent reads:**
- `{{registry_path}}` — the fresh registry the registry step just committed
- `{{scope_feedback_paths}}` — every scope's `feedback.md` (for the dedup check)

**Scanner agent writes:**
- any `feedback.md` within the scope tree, `{{invocation_log}}`, `{{warnings_file}}`

The adopter fills in their scope-tree paths (`{{scope_risk_paths}}` and
`{{scope_feedback_paths}}`) in the `sparse-checkout:` key of the `actions/checkout@v4`
step.

## Security

This implementation satisfies the three security layers of the agent security contract
([`../../../tooling/agent/spec.md`](../../../tooling/agent/spec.md) — Contract 2). All
three are enforced in the runner shell and cannot be bypassed by the model.

- **Layer 1 — Write-scope validator.** Because both agents commit separately within one
  job, use the **post-commit form** of the validator, filtered by `--author="risk-monitor"`
  (the `--author` filter is required — without it, commits from other contributors that
  land during the run window produce false positives). The validator's allowed-pattern
  regex is the union of both agents' write scopes:

  | Agent | Write-scope validator regex |
  |---|---|
  | registry | `^governance/catalogue/risks\.yaml$\|^governance/observability/` |
  | scanner | `(^\|/)feedback\.md$\|^governance/observability/` |
  | combined (one validator over both commits) | `^governance/catalogue/risks\.yaml$\|^governance/observability/\|(^\|/)feedback\.md$` |

  Anything committed by `risk-monitor` outside the combined pattern fails the step and
  blocks the run.

- **Layer 2 — Sparse checkout.** Scoped to the union of read and write paths above. Files
  outside the checkout do not exist in the working tree.

- **Layer 3 — Prompt guardrails.** Each agent step injects a mandatory preamble before
  the command prompt declaring its write scope (the registry step's preamble names the
  registry path and observability folder; the scanner step's names `feedback.md` files
  and the observability folder), plus the standard NO FABRICATION and EXIT ON UNCERTAINTY
  constraints. The EXIT ON UNCERTAINTY warning destination is `{{warnings_file}}`.

## Scheduling

Adopter-declared via `on: schedule`. Because the two agents are sequenced within one
workflow, the adopter declares a **single** cron expression for the combined
`risk-monitor` workflow.

**Recommended placement:** schedule the workflow *after* the catalogue agent's run, so
the registry agent benefits from a fresh catalogue, and so the registry's own
regeneration and the catalogue's `risk-at-scope` sync do not race. Where the catalogue
runs daily, schedule `risk-monitor` shortly after it.

## Extension points

| Extension point | Description | Default |
|---|---|---|
| `registry_path` | Where the registry agent writes the aggregated registry, and where the scanner reads it | *(required)* |
| `delta_log` | Where the registry agent appends its change log | *(required)* |
| `invocation_log` | Shared invocation log, written by both agents | *(required)* |
| `warnings_file` | Where the scanner logs registry-absent warnings and where guardrails route uncertainty | *(required)* |
| `scope_risk_paths` | Glob list of `risks/` folders across the scope tree the registry agent walks | *(required)* |
| `scope_feedback_paths` | Glob list of `feedback.md` targets across the scope tree the scanner routes to | *(required)* |
| `runner` | The `runs-on:` runner label | *(required)* |
| `llm_gateway` | The LLM gateway base URL (`ANTHROPIC_BASE_URL`) | *(required)* |
| `model` | The model id passed to `--model` | *(required)* |

## Related

- [`../../registry.md`](../../registry.md) — risk registry agent capability spec
- [`../../scanner.md`](../../scanner.md) — risk scanner agent capability spec
- [`../../../tooling/agent/spec.md`](../../../tooling/agent/spec.md) — agent pattern; the four contracts and the security layers referenced above
- [`../../../tooling/spec-health/implementations/github-actions/spec.md`](../../../tooling/spec-health/implementations/github-actions/spec.md) — the spec-health GHA implementation this spec is modelled on
