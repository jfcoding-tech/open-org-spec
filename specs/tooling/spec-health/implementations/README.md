# Spec-Health: Runtime Contract

This folder contains implementation specs for the spec-health suite. An implementation is the concrete runtime mechanism that satisfies the three shared contracts defined in [`../spec.md`](../spec.md).

Two implementations are provided. Adopters declare their chosen implementation in the adoption manifest (see below) and follow the corresponding spec. A custom implementation is also supported.

## The three shared contracts — what any implementation must satisfy

### Scheduling contract

The implementation must fire each agent at its adopter-declared schedule. Schedules are extension points declared in the suite spec; the implementation is responsible for wiring them.

### Retry contract

On any transient failure (write conflict, push failure, network error), the implementation must:

1. Re-attempt the agent after a short delay — not wait for the next scheduled window.
2. Pass the same agent prompt to the retry run, with a retry counter incremented in the prompt heading (`# <Agent Name> — attempt N of M`).
3. On exhaustion (N exceeds the adopter-declared maximum, default 3), record the failure in the adopter-declared failure log and stop.

The delay duration is declared by each implementation spec. It must be long enough to allow transient conditions (lock contention, push conflicts) to clear, but short enough that re-attempts happen within the same day.

### Observability contract

On every run — success or failure — the implementation must cause the agent to append one structured entry to the adopter-declared invocation log before exiting. On max-retry exhaustion, the implementation must cause the agent to append one entry to the adopter-declared failure log.

Entry formats are defined in each agent's capability spec.

## Provided implementations

### `claude-code`

For adopters running agents via scheduled Claude Code sessions.

- Scheduling: a scheduling mechanism fires each agent's prompt on the declared schedule.
- Retry: a wakeup mechanism schedules a delayed re-run with the incremented prompt.
- File operations and git: via available tools in the Claude Code environment.

See [`claude-code/spec.md`](claude-code/spec.md) for concrete tool names and configuration details.

**When to choose this:** you operate the repo primarily through Claude Code and want agents to run as scheduled Claude Code sessions without additional CI infrastructure.

### `github-actions`

For adopters running agents via CI workflows that call a model API.

- Scheduling: a GitHub Actions `on: schedule` workflow trigger.
- Retry: a shell-level retry loop with sleep between attempts.
- File operations and git: standard shell commands and git CLI.
- Agent execution: a workflow step calls the model API with the agent's prompt.

See [`github-actions/spec.md`](github-actions/spec.md) for workflow structure and configuration details.

**When to choose this:** you want agents to run in a reproducible CI environment, or you do not use Claude Code as your primary interface.

## Declaring an implementation in the adoption manifest

In the adoption manifest (`config.yaml`):

```yaml
capabilities:
  spec-health:
    status: active
    implementation: claude-code   # or github-actions, or custom
```

The `implementation` field is required when `status: active`. Activating spec-health without declaring an implementation is a configuration error.

## Custom implementations

A custom implementation must satisfy all three contracts above. Checklist:

- [ ] Fires each agent on a declared schedule
- [ ] On transient push or write failure, re-attempts after a short delay — not waiting for the next scheduled window
- [ ] Passes the same agent prompt to the retry run, with the retry counter incremented in the heading
- [ ] On max-retry exhaustion (N exceeds the declared maximum), records the failure in the adopter-declared failure log
- [ ] On every run (success or failure), causes the agent to append one structured entry to the adopter-declared invocation log before exiting

Declare a custom implementation in the manifest as:

```yaml
capabilities:
  spec-health:
    status: active
    implementation: custom
    implementation_spec: <relative path to your implementation spec>
```

## Related

- [`../spec.md`](../spec.md) — suite capability spec; defines the three shared contracts
- [`claude-code/spec.md`](claude-code/spec.md) — Claude Code runtime implementation
- [`github-actions/spec.md`](github-actions/spec.md) — GitHub Actions runtime implementation
