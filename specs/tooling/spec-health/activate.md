---
description: Activate the spec-health suite — wire the scheduled agents from config.yaml and instrument all commands for agent-metrics
owner: Javier Fernandez
---

# /spec-health-activate

Activates the [spec-health suite](spec.md) for an adopter repo. This command is **standalone and imperative** — it is invoked directly by the manifest owner after setting `capabilities.spec-health.status: active` in `config.yaml`. It is not called by `adhere-to`.

The command reads the adopter's spec-health declaration, wires the two scheduled agents (`conformance` and `catalogue`) for the chosen implementation, then — when `agent-metrics` is active — runs a universal instrumentation pass over every command in the adopter's command directory so all commands log to the shared invocation log.

## Preconditions

- The adoption manifest exists at `.open-org-spec/config.yaml`.
- `capabilities.spec-health.status` is `active`. If it is not, refuse — there is nothing to activate. Point the adopter at the activation requirement in [`spec.md`](spec.md#activation-requirement).
- The running contributor is the manifest owner. Activation writes scheduler wiring and instruments commands across the repo — both are manifest-owner operations.

## Step 1 — Read config.yaml

Read `.open-org-spec/config.yaml` and extract `capabilities.spec-health`:

- `implementation` — one of `claude-code`, `github-actions`, or `custom`. Required; refuse if absent.
- `github_workflows_approver` — an email. Required for `github-actions` only; ignored otherwise.
- `agents:` — the map of the two agents to their cron schedules:

  ```yaml
  agents:
    conformance:    "0 6 * * *"
    catalogue:      "0 7 * * *"
  ```

  Both keys must be present. If any agent schedule is missing, refuse and name the missing agent.

Also read the adopter wiring values the chosen implementation needs (LLM gateway, model, runner, invocation log path, and the per-agent sparse-checkout / write-scope patterns) from the adopter's wiring layer under `.open-org-spec/`. These are adopter-declared; this command consumes them, it does not invent them.

## Step 2 — Branch on implementation

### implementation: github-actions

1. **Approver check.** Compare the declared `capabilities.spec-health.github_workflows_approver` against `owner.email` in `config.yaml`.
   - If they match, proceed.
   - If they do not match, **block**. Write authority over `.github/workflows/` requires the manifest owner's approval. Explain that the declared approver (`<github_workflows_approver>`) is not the manifest owner (`<owner.email>`), so workflow generation is not authorised. Stop here — do not generate workflows and do not run the instrumentation step. Report the approver-check failure.

2. **Generate the two workflow files.** For each agent, write a workflow file under `.github/workflows/`:

   | Agent | Workflow file | Template |
   |---|---|---|
   | conformance | `.github/workflows/spec-health-conformance.yml` | `implementations/github-actions/workflows/spec-health-conformance.yml` |
   | catalogue | `.github/workflows/spec-health-catalogue.yml` | `implementations/github-actions/workflows/spec-health-catalogue.yml` |

   Each workflow is templated from the adopter-declared wiring. Substitute `{{variable}}` placeholders:
   - `{{cron_schedule}}` — read from `config.yaml#capabilities.spec-health.agents.<name>.schedule` for that agent.
   - `{{llm_gateway}}`, `{{model}}`, `{{runner}}` — from adopter wiring.
   - `{{manifest_dir}}` — the directory containing `config.yaml` (`standard#manifest_dir`, e.g. `.open-org-spec`).

   Do not overwrite a workflow file that already exists with adopter edits without surfacing it — if a target workflow already exists, report it and leave it in place unless the adopter confirms a regenerate.

3. Run the universal instrumentation step (Step 3).

### implementation: claude-code

1. Issue `CronCreate` twice, one per agent, each at the schedule read from `config.yaml#capabilities.spec-health.agents.<name>.schedule`. Each cron points at that agent's relay command file in the adopter's command directory (the per-agent prompt file per the [claude-code implementation spec](implementations/claude-code/spec.md)).

   | Agent | Schedule source | Cron target |
   |---|---|---|
   | conformance | `agents.conformance` | adopter conformance relay command file |
   | catalogue | `agents.catalogue` | adopter catalogue relay command file |

2. Run the universal instrumentation step (Step 3).

### implementation: custom

1. Read `capabilities.spec-health.implementation_spec` from `config.yaml` and defer to that spec for how the two agents are scheduled. The custom spec must satisfy the three shared contracts (scheduling, retry, observability) per [`implementations/README.md`](implementations/README.md).
2. Run the universal instrumentation step (Step 3).

## Step 3 — Universal agent-metrics instrumentation

This step runs for every implementation. It enforces the rule that when [`agent-metrics`](../agent-metrics/spec.md) is active, every command in the adopter's command directory logs its invocations — partial instrumentation skews the value baseline. See [`spec.md`](spec.md#agent-metrics-activation-implies-universal-instrumentation).

1. **Walk the command directory.** Enumerate every file in the adopter's command directory (e.g. `.claude/commands/` for Claude Code).

2. **Per command, check for a log-invocation step.** A command is already instrumented if it references the adopter-declared invocation log path anywhere in the file (the detection signal: a reference to the invocation log path). If found, skip — already instrumented.

3. **Check opt-out.** If the command's frontmatter declares `observability: false`, skip it and count it as opted out. Opt-out is explicit; opt-in is the default.

4. **Inject the log-invocation step.** For a command that is neither already instrumented nor opted out, append a log-invocation step at the end of the command file. Precede the step with the idempotency marker on its own line:

   ```
   <!-- oos:observability-instrumented -->
   ```

   The marker guarantees re-runs do not duplicate the step — on a later run, treat the presence of `<!-- oos:observability-instrumented -->` as already instrumented and skip.

   The injected step appends one entry to the adopter-declared invocation log at the end of every run of that command:

   ```
   YYYY-MM-DD HH:MM UTC | /<command-name> | files_read: N | catalogue_assisted: true/false | outcome: success/fail
   ```

   `files_read` is the count of distinct files the command opened during the run; `catalogue_assisted: true` when the command read the catalogue instead of walking the filesystem for that data.

5. **Count.** Track N = commands instrumented this run, M = commands skipped via `observability: false`. Commands already instrumented (marker or existing log reference present) are neither in N nor M — report them separately if useful.

## Step 4 — Report

Report what was wired:

- **Implementation** chosen (`claude-code`, `github-actions`, or `custom`).
- **Approver check** (github-actions only): pass (approver == manifest owner) or the blocked outcome with both emails named.
- **Schedules / workflows created**: the two agents and their schedules — for github-actions, the two workflow file paths written; for claude-code, the two `CronCreate` targets; for custom, a pointer to the custom spec.
- **Commands instrumented**: N injected, M opted out via `observability: false`, plus the count already instrumented.

If the approver check blocked (github-actions), the report states that no workflows were generated and no instrumentation ran, and points the adopter to obtain the manifest owner's approval.

## Related

- [`spec.md`](spec.md) — spec-health suite spec; activation flow and the universal-instrumentation requirement.
- [`implementations/claude-code/spec.md`](implementations/claude-code/spec.md) — `CronCreate` wiring per agent.
- [`implementations/github-actions/spec.md`](implementations/github-actions/spec.md) — workflow structure and the two workflow templates.
- [`implementations/README.md`](implementations/README.md) — runtime contract for custom implementations.
