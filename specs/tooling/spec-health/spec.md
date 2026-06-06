# Spec-Health Suite

**Owner:** Javier Fernandez
**Status:** Active

A suite of coordinated agents that maintain the health of a spec-driven repository — conformance detection and catalogue currency. Each agent handles one concern; together they keep specs conformant and the catalogue fresh.

## Purpose

A spec-driven repository drifts without active maintenance: required fields go missing and the central catalogue grows stale. The spec-health suite addresses these failure modes through agents that run on a schedule, write structured output to the repo, and report their own activity so the cost and value of the system is visible.

The suite is designed for adoption: agent logic is written generically, and adopters declare their own paths, schedules, routing tables, and implementation in a wiring layer separate from the generic core.

Two concerns that previously lived in this suite are now standalone capabilities and are no longer part of spec-health: stale-decision remediation moved to [`decision-escalation`](../../governance-at-scope/tools/decision-escalation/spec.md) under `governance-at-scope` tooling, and value measurement moved to [`agent-metrics`](../agent-metrics/spec.md) under the tooling capability (where it measures all agents and commands, not just this suite).

## Agents in the suite

| Agent | Concern | When it runs |
|---|---|---|
| `conformance` | Detects specs missing required fields; nudges owners | Daily |
| `catalogue` | Regenerates the adopter's catalogue from the repo state | Daily |

The `catalogue` agent is now a [standalone capability](../catalogue/spec.md). The spec-health suite depends on it — the conformance agent reads the catalogue rather than walking the filesystem — but it is governed and specified under `specs/tooling/catalogue/`, not within this suite. It is listed here because the suite schedules and sequences it alongside conformance.

## Outputs

All outputs written by the suite, in one place. Individual agent specs define the formats in detail; this table gives the cross-cutting view.

| Agent | Output | Location | When written |
|---|---|---|---|
| conformance | Nudge entry per non-conformant spec | `<scope>/feedback.md` (routed by scope) | Each non-conformant spec found |
| catalogue | Full split catalogue (index + sub-files) | adopter-declared catalogue base path | Daily — full rewrite |
| **all agents** | Invocation log entry | adopter-declared invocation log | Every run (success or failure) |
| **all agents** | Failure log entry | adopter-declared failure log | Max-retry exhaustion only |

### Feedback inbox outputs (distributed)

Conformance writes to whichever scope's `feedback.md` is relevant — not to a single file. The scope-to-feedback-inbox routing table each adopter declares defines the mapping. Example: a non-conformant spec under a cluster scope writes to that cluster's `feedback.md`.

```
conformance ──► <scope-A>/feedback.md
            ──► <scope-B>/feedback.md
            ──► <scope-C>/feedback.md
            ──► ...
```

### Structured outputs (centralised)

```
<adopter-declared catalogue base path>     ◄── catalogue agent (daily rewrite of index + sub-files)
<adopter-declared invocation log path>     ◄── all agents (one line per run)
<adopter-declared failure log path>        ◄── all agents (one line per exhaustion)
```

The weekly value report is no longer a spec-health output — it is produced by [`agent-metrics`](../agent-metrics/spec.md), which reads the same invocation and failure logs.

## Dependency chain

The agents are sequenced intentionally:

1. **Conformance runs first** — detects gaps and nudges owners before the catalogue snapshot is taken. Same-day fixes by contributors are captured in the catalogue run.
2. **Catalogue runs second** — regenerates the adopter's catalogue after any fixes from step 1. The catalogue is a [standalone capability](../catalogue/spec.md); the suite schedules it after conformance so the day's snapshot reflects same-day fixes.

### Daily schedule

```
       ┌─────────────┐   nudges    ┌───────────────┐
       │ conformance │────────────►│ feedback.md   │◄── contributor fixes specs
       └─────────────┘             └───────┬───────┘
                                           │ (same-day fixes captured)
       ┌─────────────┐                     │
       │  catalogue  │◄────────────────────┘
       └──────┬──────┘
              │ regenerates
              ▼
       ┌──────────────────────┐
       │ adopter catalogue    │
       │ (index + sub-files)  │
       └──────────────────────┘
```

The stale-decision and value-measurement steps that previously ran on a weekly cadence are now external: [`decision-escalation`](../../governance-at-scope/tools/decision-escalation/spec.md) routes disposition requests for stale decisions, and [`agent-metrics`](../agent-metrics/spec.md) reads the invocation and failure logs to write the weekly value report. Both run on their own schedule, declared by the adopter where those capabilities are activated — not by this suite.

### Invocation log (all agents, every run)

```
conformance ──┐
catalogue   ──┴──► adopter invocation log

on exhaustion:
any agent ────────► adopter failure log
```

## Shared contracts

All agents in the suite implement these three contracts without exception. These contracts are defined here as abstract obligations; concrete tool names and mechanisms belong in the implementation specs under `implementations/`.

### Retry topology (all agents)

```
scheduled trigger
      │
      ▼
 attempt N of M ──► verify repo safe to write
      │                      │
      │              ┌───────┴───────┐
      │           safe?          not safe?
      │              │               │
      │              ▼               ▼
      │         write + push     schedule retry
      │              │           (delay, N+1)
      │      ┌───────┴───────┐        │
      │   success?        fail?        │
      │      │               │        │
      │      ▼               ▼        │
      │  log + done    schedule retry ◄┘
      │                (delay, N+1)
      │
      │  if N > max:
      └──────────────► log failure + stop
```

The retry delay and maximum attempts are declared by the adopter (see extension points). The agent prompt heading carries the counter so the retry run knows its position: `# <Agent> — attempt N of M`.

---

### Scheduling contract

Each agent fires on a schedule declared by the adopter. The schedule for each agent is an extension point (see the extension points table below). An implementation must provide a mechanism that fires each agent at its declared time.

### Retry contract

On transient failure (a write conflict, a push that fails because the branch has diverged, a network error), the agent re-attempts rather than waiting for the next scheduled window. The retry behaviour:

1. Before any write, verify the repo is in a state safe to write to. On failure, treat as push-risk and schedule a retry.
2. On push failure, schedule a retry with a short delay. Pass the same agent prompt to the retry run, with the retry counter incremented by 1.
3. The agent prompt heading carries the retry counter: `# <Agent Name> — attempt N of M`.
4. The maximum number of attempts is declared by the adopter (default 3). N starts at 1 on the schedule-triggered run.
5. On exhaustion (N exceeds the declared maximum), record the failure in the adopter-declared failure log and stop.

### Observability contract

Each agent run produces a structured record of what happened:

- **Invocation log entry** — on every run (success or failure), the agent appends one entry to the adopter-declared invocation log:

  ```
  YYYY-MM-DD HH:MM UTC | <agent> | files_read: N | catalogue_assisted: true/false | outcome: success/fail | spec_version: <version>
  ```

  `catalogue_assisted: true` when the agent read the catalogue file rather than walking the filesystem directly. The `catalogue` agent writes `false` because it generates, not consumes.

- **Failure log entry** — on max-retry exhaustion, the agent appends one entry to the adopter-declared failure log:

  ```
  YYYY-MM-DD HH:MM UTC | <agent> | attempt <N> failed: <reason>
  ```

  The failure log is separate from the invocation log so failures are easy to find without parsing outcomes.

## Extension points

Adopters declare the following values when activating this capability:

| Extension point | Description | Default |
|---|---|---|
| Invocation log path | Where all agents append their per-run entry | *(required)* |
| Failure log path | Where all agents append on max-retry exhaustion | *(required)* |
| Catalogue base path | The catalogue index and sub-files agents read and write | *(required)* |
| Max retry attempts | Maximum attempts per agent run before failure is recorded | 3 |
| Conformance schedule | When the conformance agent fires | Daily |
| Catalogue schedule | When the catalogue agent fires | Daily, after conformance |

Each agent capability spec defines its own additional extension points (paths, thresholds, vocabularies, routing tables).

## Activation flow

Activation wires the scheduled agents from a single config declaration. The adopter runs `/spec-health-activate` after updating `config.yaml`.

```
config.yaml
┌──────────────────────────────────┐
│ capabilities:                    │
│   spec-health:                   │
│     status: active               │
│     implementation: claude-code  │  ◄── or github-actions
│     github_workflows_approver:   │      (required for github-actions only;
│       <email>                    │       checked against governance authority)
│     agents:                      │
│       conformance:  "0 6 * * *"  │
│       catalogue:    "0 7 * * *"  │
└──────────────┬───────────────────┘
               │
               ▼
  /spec-health-activate
               │
       ┌───────┴────────────────────────────┐
       │  reads implementation field         │
       └───────┬───────────────┬────────────┘
               │               │
    claude-code?           github-actions?
               │               │
               ▼               ▼
        CronCreate × 2    check approver
        (one per agent,   against governance
         at declared         │
         schedule)      ┌────┴─────┐
                      authorised?  not authorised?
                          │              │
                          ▼              ▼
                  generate          block + point
                  .github/          to governance
                  workflows/*.yml
```

## Activation requirement

When activating this capability in the adoption manifest, the adopter **must** declare an implementation:

```yaml
capabilities:
  spec-health:
    status: active
    implementation: claude-code   # or github-actions, or custom
```

Two implementations are provided under `implementations/`:
- `claude-code` — for adopters running agents via scheduled Claude Code sessions
- `github-actions` — for adopters running agents via CI workflows calling the model API

A custom implementation must satisfy all three shared contracts above. See [`implementations/README.md`](implementations/README.md) for the runtime contract and a checklist for custom implementations.

### Agent-metrics activation implies universal instrumentation

When [`agent-metrics`](../agent-metrics/spec.md) is active, **all commands in the adopter's command directory must include a log-invocation step.** Partial instrumentation produces a skewed baseline and a false picture of system value. This is an agent-metrics concern rather than a spec-health one — the suite documents it here because the spec-health agents are among the agents agent-metrics measures, and the activate command performs the instrumentation pass.

The activate command enforces this automatically:

1. On activation, it walks every file in the command directory.
2. For each command spec found, it checks for a log-invocation step. If absent, it adds one.
3. Commands may opt out by declaring `observability: false` in their spec frontmatter. Opt-out is explicit; opt-in is the default.
4. Any command created after activation must include the log-invocation step at authoring time. Command templates should include it by default.

The log-invocation step appends one entry to the adopter-declared invocation log at the end of every command run:

```
YYYY-MM-DD HH:MM UTC | /<command-name> | files_read: N | catalogue_assisted: true/false | outcome: success/fail | spec_version: <version>
```

`files_read` is the count of distinct files the command opened during the run. `catalogue_assisted: true` when the command read the catalogue instead of walking the filesystem for that data.

## Artefacts

The suite's log files are written by multiple automated agents and by the invocation log step in every command. Concurrent commits cause merge conflicts unless git is configured to use a union merge strategy for these files. `adhere-to spec-health` scaffolds these entries automatically.

```yaml
artefacts:
  - id: invocation-log-gitattributes
    type: gitattributes_entry
    path: .gitattributes
    variables:
      - name: manifest_dir
        source: standard#manifest_dir
    check:
      type: gitattributes_entry
      value: "{{manifest_dir}}/spec-health/invocation-log.md merge=union"

  - id: failure-log-gitattributes
    type: gitattributes_entry
    path: .gitattributes
    variables:
      - name: manifest_dir
        source: standard#manifest_dir
    check:
      type: gitattributes_entry
      value: "governance/observability/spec-health/agent-failures.md merge=union"

  - id: warnings-log-gitattributes
    type: gitattributes_entry
    path: .gitattributes
    variables:
      - name: manifest_dir
        source: standard#manifest_dir
    check:
      type: gitattributes_entry
      value: "governance/observability/spec-health/agent-warnings.md merge=union"
```

The `merge=union` strategy keeps all lines from both sides of a conflict — correct for append-only logs. Without these entries, concurrent agent commits and contributor commits produce rebase conflicts on every run.

## Related

- [`activate.md`](activate.md) — the `/spec-health-activate` command that wires the suite from `config.yaml`
- [`conformance/spec.md`](conformance/spec.md) — conformance agent capability spec
- [`../catalogue/spec.md`](../catalogue/spec.md) — catalogue capability spec (standalone; the suite depends on it)
- [`../../governance-at-scope/tools/decision-escalation/spec.md`](../../governance-at-scope/tools/decision-escalation/spec.md) — stale-decision remediation, formerly `decision-nudge`; now a governance-at-scope tool
- [`../agent-metrics/spec.md`](../agent-metrics/spec.md) — repo-wide value measurement, formerly the observability agent; now a standalone tooling capability
- [`implementations/README.md`](implementations/README.md) — runtime contract; pick an implementation or declare a custom one
- [`implementations/claude-code/spec.md`](implementations/claude-code/spec.md) — Claude Code runtime implementation
- [`implementations/github-actions/spec.md`](implementations/github-actions/spec.md) — GitHub Actions runtime implementation
