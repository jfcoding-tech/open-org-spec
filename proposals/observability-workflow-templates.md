---
change: observability-workflow-templates
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Observability workflow templates — ship working GHA workflows with the spec

## Intent

Ship two complete, parameterised GitHub Actions workflow templates with the observability capability so that adopters get working scheduled execution from `/adhere-to tooling` with no GHA knowledge required:

1. **Suite workflow template** at `specs/observability/suite/workflow.yml` — runs the six data-collection agents (`owner-health`, `inbox-health`, `decision-health`, `contributor-activity`, `spec-activity`, `risk-load`) on a weekly schedule. Encodes every guardrail proven in the reference adopter's `governance-observability.yml`: CLAUDE.md stub replacement, the write-scope pre-commit hook, `git checkout -- .` before `git pull --rebase` in every retry loop, and failure logging to `agent-failures.md` when a push exhausts its attempts. When `/adhere-to tooling` runs, this template **replaces** the adopter's `governance-observability.yml`.

2. **Governance Pulse workflow template** at `specs/observability/governance-pulse/workflow.yml` — a standalone rendering workflow triggered by `workflow_run` (after the data-collection suite + spec-health complete) and by `workflow_dispatch`. Uses a minimal sparse checkout (`governance/`, `.claude/commands/`, `.open-org-spec/` only — no full repo walk), needs no CLAUDE.md stub (it renders pre-generated data, it does not scan the org), and runs a single `governance-pulse` step on the Sonnet-class model.

Template variables, common to both: `{{runner}}`, `{{schedule}}`, and the model id (`{{model_haiku}}` for the suite, `{{model_sonnet}}` for the report).

## Rationale

**The reference adopter proved the workflow before the standard described it, and the standard's `suite.md` currently under-specifies it.** The `suite.md` spec names the contracts at the suite level — write-scope validator, checkout scope, prompt guardrails, retry topology — but stops at *requirements*. An adopter reading it still has to author a multi-hundred-line GitHub Actions file by hand and rediscover the operational details that only surface when the workflow runs unattended in CI against a moving `main`. The reference adopter rediscovered all of them the hard way; the resulting `governance-observability.yml` encodes fixes that are invisible in the prose spec but load-bearing in practice:

- **CLAUDE.md stub replacement.** An agent running headless must not read the adopter's full contributor guide — it would try to invoke `/catchup`, honour ownership-consent prompts, and otherwise behave as if a human were present. The reference workflow overwrites `CLAUDE.md` with a one-line agent stub for the duration of the run. The prose spec never mentions this, so a hand-authored workflow omits it and the agent misbehaves.
- **Write-scope pre-commit hook.** Layer 1 in `suite.md` is a *post*-execution validator that reverts out-of-scope writes. The reference adopter found that a *pre-commit* hook installed at run start (refusing to stage anything outside `governance/observability/`) is a stronger guard — it stops the bad write from ever entering a commit, rather than catching it after. Both layers belong; the spec only describes one.
- **`git checkout -- .` before every `git pull --rebase`.** Unattended runs against a moving `main` hit rebase conflicts when an agent leaves the working tree dirty. Discarding uncommitted changes before each rebase attempt is what makes the retry loop actually converge. This is the single most easily-omitted line and the one that causes the most opaque CI failures when missing.
- **Failure logging to `agent-failures.md`.** When push retries exhaust, the run must leave a durable trace in the repo, not just a red X in the Actions UI that no one watches. The reference workflow appends a dated line to `governance/observability/spec-health/agent-failures.md` and force-commits *that one file* before exiting non-zero.

Codifying these as templates that ship with the spec means the next adopter inherits the fixes instead of rediscovering them. This is the same principle the Governance Pulse proposal established for the command template: **the standard provides complete, working tools; adopters extend rather than implement.** The workflow is as much a part of the tool as the command file is.

**Governance Pulse must be decoupled from the data-collection suite.** Today the reference adopter renders the report as the final step *inside* `governance-observability.yml`. That coupling has a failure mode: if any of the six data agents fails its push-retry loop and exits non-zero, the job stops and the report step never runs — so a single data-collection hiccup blocks the stakeholder-facing artefact, even though the report only needs the *previously generated* outputs and would render fine from the last good data. The report is a rendering tool, not a collection tool: it reads pre-generated `governance/observability/*.md` and `governance/catalogue/*.yaml` and produces HTML. It should run on its own workflow, triggered by `workflow_run` after the collection suite completes (success *or* failure — `workflow_run` fires regardless, and the report's own freshness timestamps make partial-data runs legible per the `governance-pulse` spec) and by `workflow_dispatch` for on-demand rendering. Decoupling also lets the report run on a different cadence (e.g. daily over weekly-refreshed data) without touching the collection workflow.

**Why a minimal checkout for the report and a full checkout for the suite.** The collection agents scan the whole org, so the suite's checkout includes every governed scope. The report agent only reads `governance/` (the generated outputs and catalogue), `.claude/commands/` (its own command file for the prompt), and `.open-org-spec/` (manifest for extension-point values). A minimal sparse checkout is faster, and — more importantly — it is a least-privilege guard: a rendering agent that cannot read `clusters/` or `projects/` cannot fabricate from them. The open-org-spec submodule is excluded from both checkouts; the contracts in `suite.md` already require the agents to be self-contained and not read `open-org-spec/`.

**Why templates and not a hand-off doc.** The alternative — documenting the patterns in prose and asking adopters to write their own workflow — is what `suite.md` does today, and it does not work: the load-bearing details are operational, not conceptual, and prose loses them. A parameterised template with three substituted variables (`runner`, `schedule`, model id) and everything else fixed is the right altitude: the adopter declares the three things that are genuinely environment-specific and inherits every guardrail. `/adhere-to tooling` installs the templates with variables resolved from the manifest, exactly as it installs command files.

## Delta

### New artefact 1 — Suite workflow template

New file `specs/observability/suite/workflow.yml`. A parameterised GitHub Actions workflow generated into the adopter's `.github/workflows/` by `/adhere-to tooling`. Header comment block documents the template source and the substituted variables, following the convention in `specs/tooling/spec-health/implementations/github-actions/workflows/spec-health-catalogue.yml`.

Template variables:

| Variable | Source | Default |
|---|---|---|
| `{{runner}}` | `config.yaml#capabilities.observability.suite.runner` | *(required)* |
| `{{schedule}}` | `config.yaml#capabilities.observability.suite.schedule` | `30 6 * * 0` (weekly Sunday 06:30 UTC) |
| `{{model_haiku}}` | `config.yaml#capabilities.observability.suite.model` | Haiku-class model id |
| `{{llm_gateway}}` | adopter-declared LLM gateway base URL | *(required)* |
| `{{observability_path}}` | `config.yaml#capabilities.observability.output_path` | `governance/observability/` |
| `{{warnings_file}}` | capability extension | `governance/observability/spec-health/agent-warnings.md` |
| `{{failures_file}}` | capability extension | `governance/observability/spec-health/agent-failures.md` |

Fixed structure (encoded once in the template, not adopter-variable):

- **Triggers:** `schedule` (cron = `{{schedule}}`) and `workflow_dispatch`.
- **Job setup:** sparse checkout of all governed scopes plus `.claude/commands` and `.open-org-spec` (open-org-spec submodule excluded — agents self-contained); `fetch-depth: 0`; `permissions: contents: write`; `timeout-minutes: 60`.
- **Sync check:** `git pull --ff-only` with a `DIVERGED` output that gates every agent step (`if: steps.sync.outputs.DIVERGED != 'true'`).
- **Baseline SHA capture** for the final write-scope validation.
- **CLAUDE.md stub replacement** — overwrite `CLAUDE.md` with a one-line agent-mode stub.
- **Write-scope pre-commit hook install** — refuses to stage any file outside `{{observability_path}}`.
- **Six sequential agent steps** — `owner-health`, `inbox-health`, `decision-health`, `contributor-activity`, `spec-activity`, `risk-load`. Each step: extract the command prompt from `.claude/commands/<tool>.md` (stripping front-matter), prepend the guardrail preamble (write-scope + no-fabrication + exit-on-uncertainty per `suite.md` Layer 3), invoke the Haiku-class model, stage `{{observability_path}}`, commit if changed, then a 3-attempt push-retry loop with **`git checkout -- .` before each `git pull --rebase`** and a 30s backoff. On exhaustion: append a dated line to `{{failures_file}}`, force-commit that one file, exit 1.
- **Final write-scope validator** — diffs the commits authored since baseline SHA against the allowed output paths and exits 1 on any unexpected file (Layer 1 post-execution validator from `suite.md`).

This template **replaces** the adopter's existing collection workflow (the reference adopter's `governance-observability.yml`) when `/adhere-to tooling` runs — the Governance Pulse render step is removed from it and migrates to the standalone report workflow below.

### New artefact 2 — Governance Pulse workflow template

New file `specs/observability/governance-pulse/workflow.yml`. A standalone rendering workflow generated into the adopter's `.github/workflows/` by `/adhere-to tooling`. Same header-comment convention.

Template variables:

| Variable | Source | Default |
|---|---|---|
| `{{runner}}` | `config.yaml#capabilities.observability.governance_pulse.runner` | *(required)* |
| `{{schedule}}` | `config.yaml#capabilities.observability.governance_pulse.schedule` | *(optional — may render on `workflow_run` alone)* |
| `{{model_sonnet}}` | `config.yaml#capabilities.observability.governance_pulse.model` | Sonnet-class model id |
| `{{llm_gateway}}` | adopter-declared LLM gateway base URL | *(required)* |
| `{{output_path}}` | `config.yaml#capabilities.observability.output_path` + `governance-pulse.html` | `governance/observability/governance-pulse.html` |

Fixed structure:

- **Triggers:** `workflow_run` (after the data-collection suite **and** spec-health complete, `types: [completed]`), plus `workflow_dispatch`, plus optional `schedule` when `{{schedule}}` is declared. `workflow_run` fires on success or failure; the report renders from whatever outputs exist, and its per-section freshness timestamps (per the `governance-pulse` spec) make partial-data runs legible.
- **Minimal sparse checkout** — `governance/`, `.claude/commands/`, `.open-org-spec/` only. No full repo walk. open-org-spec submodule excluded.
- **No CLAUDE.md stub** — the render agent does not scan the org or invoke contributor-facing commands, so no stub is needed.
- **Single `governance-pulse` step** — extract the prompt from `.claude/commands/governance-pulse.md`, prepend the render-scoped guardrail (write to `{{output_path}}` only; all values from `governance/observability/*.md` and `governance/catalogue/*.yaml`; exit-on-uncertainty to the warnings file), invoke the Sonnet-class model, stage `{{output_path}}`, commit if changed, then the same 3-attempt push-retry loop with **`git checkout -- .` before each `git pull --rebase`**. On exhaustion: log to the failures file and exit 1.

### Spec text changes

In `specs/observability/suite.md` (Contract 3 — Implementation):
- Add the four operational requirements as named, mandatory elements rather than implicit: CLAUDE.md stub replacement, write-scope pre-commit hook (alongside the existing Layer 1 post-execution validator), `git checkout -- .` before each rebase, and failure logging to the adopter-declared failures file.
- Point to `./suite/workflow.yml` as the reference template `/adhere-to tooling` installs.

In `specs/observability/governance-pulse/spec.md`:
- Under "Implementation pattern," replace "Writes to the declared output path and commits alongside the other suite outputs" with the decoupled model: the report runs as a **standalone** workflow triggered by `workflow_run` after the collection suite, not as a final step inside it. Add `./workflow.yml` to the Artefacts block as a `file` artefact with `template: specs/observability/governance-pulse/workflow.yml`.

### Artefacts blocks

Both templates are added to their respective specs' Artefacts blocks so `/adhere-to tooling` installs them, with variables resolved from the manifest and the defaults above.

## Acceptance scenarios

### New adopter gets a working collection workflow with no GHA knowledge

Given an adopter with observability + suite active who has declared `runner`, `schedule`, and `model` in their manifest
When they run `/adhere-to tooling`
Then `.github/workflows/observability-suite.yml` is installed with the three variables resolved
And the workflow contains the CLAUDE.md stub replacement, the write-scope pre-commit hook, the six agent steps, and a `git checkout -- .` before every `git pull --rebase`
And the adopter never had to author any GitHub Actions YAML by hand

### Template replaces the legacy coupled workflow

Given the reference adopter whose `governance-observability.yml` renders Governance Pulse as its final step
When `/adhere-to tooling` runs after this change lands
Then the collection workflow is replaced by the suite template (no render step)
And the Governance Pulse render step now lives in a separate `governance-pulse.yml` workflow

### A data-agent failure no longer blocks the report

Given the collection suite where `decision-health` exhausts its push retries and the suite job exits non-zero
When the `governance-pulse` workflow's `workflow_run` trigger fires on completion
Then the report still renders from the most recent generated outputs
And the report's per-section freshness timestamps show which dimensions are stale
And the stakeholder-facing artefact is produced despite the upstream failure

### Report workflow uses least-privilege checkout

Given the Governance Pulse workflow running
When the checkout step completes
Then only `governance/`, `.claude/commands/`, and `.open-org-spec/` are present in the working tree
And `clusters/`, `projects/`, and the open-org-spec submodule are absent
And the render agent cannot read or fabricate from scopes outside `governance/`

### Push retry converges against a moving main

Given an agent step whose commit conflicts with a concurrent push to `main`
When the retry loop runs
Then `git checkout -- .` discards the dirty working tree before each `git pull --rebase`
And the rebase succeeds rather than failing on uncommitted changes
And the push succeeds within the three attempts

### Exhausted push leaves a durable trace

Given an agent step whose push fails all three attempts
When the loop exhausts
Then a dated line is appended to the adopter-declared failures file
And that one file is force-committed and pushed
And the step exits non-zero so the run is visibly failed in the Actions UI

## Related

- `specs/observability/suite.md` — the suite execution spec this template implements; gains the four named operational requirements
- `specs/observability/governance-pulse/spec.md` — the report spec; gains the standalone-workflow implementation model and the `workflow.yml` artefact
- `specs/observability/spec.md` — parent observability capability
- `specs/tooling/spec-health/implementations/github-actions/workflows/spec-health-catalogue.yml` — the workflow-template convention (header comment, variable substitution) this proposal follows
- `specs/tooling/adhere-to/spec.md` — the tool that installs the templates with manifest-resolved variables
