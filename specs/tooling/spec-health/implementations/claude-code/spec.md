# Spec-Health: Claude Code Implementation

**Owner:** Javier Fernandez
**Status:** Active

The Claude Code runtime implementation for the spec-health suite. Satisfies the three shared contracts (scheduling, retry, observability) using Claude Code-native tools. Tool names and mechanisms are concrete here; they are absent from the capability specs.

## How it satisfies the shared contracts

### Scheduling contract — `CronCreate`

Each agent is wired using `CronCreate`, which fires the agent's prompt on the declared schedule. The prompt file for each agent is the relay at its adopter-declared command path.

Per-agent wiring:

| Agent | CronCreate schedule | Prompt file |
|---|---|---|
| conformance | adopter-declared conformance schedule | adopter-declared conformance prompt |
| catalogue | adopter-declared catalogue schedule | adopter-declared catalogue prompt |

The `decision-escalation` and `agent-metrics` agents are no longer part of this suite. Adopters who run them via scheduled Claude Code sessions wire their `CronCreate` entries from those capabilities, not here.

The `CronCreate` call is made once at activation time. Schedules are adjusted by updating the cron wiring to match any changes to the suite spec's extension point values.

### Retry contract — `ScheduleWakeup`

**Before any write:** the agent runs `git pull --ff-only`. On failure (diverged branch, network error), treat as push-risk: do not proceed. Call `ScheduleWakeup` with the retry prompt.

**On push failure:** call `ScheduleWakeup` with:

```
delaySeconds: 480
prompt: <same agent prompt, with heading incremented to "attempt N+1 of M">
```

The 480-second delay is within the `ScheduleWakeup` runtime's clamped range of [60, 3600] seconds.

**Retry counter in prompt heading:** the agent prompt heading carries the counter on every run:

```
# <Agent Name> — attempt N of M
```

N starts at 1 on the cron-triggered run. M is the adopter-declared maximum (default 3).

**On exhaustion (N > M):** write a failure entry to the adopter-declared failure log using the Write or Edit tool, then stop. Do not call `ScheduleWakeup` again.

### Observability contract — Write / Edit tool

Before exiting, the agent appends one structured entry to the adopter-declared invocation log using the Write or Edit tool. On exhaustion, the agent also appends one entry to the adopter-declared failure log before stopping.

Entry formats are defined in each agent's capability spec.

## File and version control operations

| Operation | Tool |
|---|---|
| Read spec files, logs, catalogue | `Read` tool |
| Write catalogue, log entries, nudge entries | `Write` or `Edit` tool |
| `git pull --ff-only` | `Bash` tool |
| `git log -1 --format="%ai" -- <path>` (last-edited date) | `Bash` tool |
| `git add`, `git commit`, `git push` | `Bash` tool |

Git operations are issued via the `Bash` tool. The agent constructs the git command and executes it; it does not rely on any git abstraction layer.

## Activation in the manifest

```yaml
capabilities:
  spec-health:
    status: active
    implementation: claude-code
```

After adding this entry, run `CronCreate` for each of the two agents with the schedule and prompt file from the per-agent wiring table above.

## Notes

- The `ScheduleWakeup` delay of 480 seconds (8 minutes) is chosen to allow transient push conflicts and lock contention to clear without waiting for the next scheduled window (which could be 24 hours away for daily agents).
- Each agent's `CronCreate` entry is independent. A failure in one agent does not affect the schedule of others.
- The retry counter is carried in the prompt heading — not as a separate file or state variable — so it survives across Claude Code sessions without requiring persistent state outside the prompt.

## Related

- [`../README.md`](../README.md) — runtime contract; three shared contracts any implementation must satisfy
- [`../../spec.md`](../../spec.md) — suite capability spec; abstract contracts
- [`../../conformance/spec.md`](../../conformance/spec.md) — conformance agent capability spec
- [`../../../catalogue/spec.md`](../../../catalogue/spec.md) — catalogue capability spec (standalone)
