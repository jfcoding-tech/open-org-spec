# Spec-Health Suite

**Owner:** Javier Fernandez
**Status:** Active

A suite of coordinated agents that maintain the health of a spec-driven repository — conformance, data currency, stale-decision remediation, and value measurement. Each agent handles one concern; together they form a closed loop.

## Purpose

A spec-driven repository drifts without active maintenance: required fields go missing, a central catalogue grows stale, proposed decisions remain unresolved, and nobody can tell whether the infrastructure is paying off. The spec-health suite addresses all four failure modes through agents that run on a schedule, write structured output to the repo, and report their own activity so the cost and value of the system is visible.

The suite is designed for adoption: agent logic is written generically, and adopters declare their own paths, schedules, routing tables, and implementation in a wiring layer separate from the generic core.

## Agents in the suite

| Agent | Concern | When it runs |
|---|---|---|
| `conformance` | Detects specs missing required fields; nudges owners | Daily |
| `catalogue` | Regenerates the adopter's spec catalogue from the repo state | Daily |
| `decision-nudge` | Detects stale open decisions; nudges owners | Weekly |
| `observability` | Reads invocation and failure logs; writes the weekly value report | Weekly |

## Outputs

All outputs written by the suite, in one place. Individual agent specs define the formats in detail; this table gives the cross-cutting view.

| Agent | Output | Location | When written |
|---|---|---|---|
| conformance | Nudge entry per non-conformant spec | `<scope>/feedback.md` (routed by scope) | Each non-conformant spec found |
| catalogue | Full spec catalogue | adopter-declared catalogue path | Daily — full rewrite |
| decision-nudge | Nudge entry per stale open decision | `<scope>/feedback.md` (routed by scope) | Each stale decision found |
| observability | Weekly report section | adopter-declared report file | Weekly — appended, never overwritten |
| **all agents** | Invocation log entry | adopter-declared invocation log | Every run (success or failure) |
| **all agents** | Failure log entry | adopter-declared failure log | Max-retry exhaustion only |

### Feedback inbox outputs (distributed)

Conformance and decision-nudge write to whichever scope's `feedback.md` is relevant — not to a single file. The scope-to-feedback-inbox routing table each adopter declares defines the mapping. Example: a non-conformant spec under a cluster scope writes to that cluster's `feedback.md`.

```
conformance ──► <scope-A>/feedback.md
            ──► <scope-B>/feedback.md
            ──► <scope-C>/feedback.md
            ──► ...

decision-nudge ──► (same routing, driven by decision record's scope)
```

### Structured outputs (centralised)

```
<adopter-declared catalogue path>          ◄── catalogue agent (daily rewrite)
<adopter-declared invocation log path>     ◄── all agents (one line per run)
<adopter-declared failure log path>        ◄── all agents (one line per exhaustion)
<adopter-declared report file path>        ◄── observability agent (weekly append)
```

## Dependency chain

The agents are sequenced intentionally:

1. **Conformance runs first** — detects gaps and nudges owners before the catalogue snapshot is taken. Same-day fixes by contributors are captured in the catalogue run.
2. **Catalogue runs second** — regenerates the adopter's spec catalogue after any fixes from step 1.
3. **Decision-nudge runs third** — scans decision records independently; shares the retry topology but does not depend on conformance or catalogue output.
4. **Observability runs last** — reads the invocation log and the catalogue produced by all prior agents on the same day.

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
       │ file                 │
       └──────────────────────┘
```

### Weekly additions

```
       ┌───────────────┐  nudges    ┌───────────────┐
       │ decision-nudge│───────────►│ feedback.md   │
       └───────────────┘            │ (per scope)   │
                                    └───────────────┘

       ┌───────────────┐  reads     ┌──────────────────────────────────────────┐
       │ observability │───────────►│ adopter invocation log                   │
       └───────┬───────┘            │ adopter failure log                      │
               │        reads       │ adopter catalogue file                   │
               │────────────────────│                                          │
               │                    └──────────────────────────────────────────┘
               │ writes
               ▼
       ┌──────────────────────────────────────────┐
       │ adopter report file                       │
       └──────────────────────────────────────────┘
```

### Invocation log (all agents, every run)

```
conformance ──┐
catalogue   ──┼──► adopter invocation log
decision-nudge┤
observability ┘

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
  YYYY-MM-DD HH:MM UTC | <agent> | files_read: N | catalogue_assisted: true/false | outcome: success/fail
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
| Catalogue path | The spec catalogue file agents read and write | *(required)* |
| Max retry attempts | Maximum attempts per agent run before failure is recorded | 3 |
| Conformance schedule | When the conformance agent fires | Daily |
| Catalogue schedule | When the catalogue agent fires | Daily, after conformance |
| Decision-nudge schedule | When the decision-nudge agent fires | Weekly |
| Observability schedule | When the observability agent fires | Weekly, after decision-nudge |

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
│       decision-nudge:"0 22 * * 0" │
│       observability:"0 10 * * 1" │
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
        CronCreate × 4    check approver
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

### Observability activation implies universal instrumentation

When the observability agent is active, **all commands in the adopter's command directory must include a log-invocation step.** Partial instrumentation produces a skewed baseline and a false picture of system value.

The activate command enforces this automatically:

1. On activation, it walks every file in the command directory.
2. For each command spec found, it checks for a log-invocation step. If absent, it adds one.
3. Commands may opt out by declaring `observability: false` in their spec frontmatter. Opt-out is explicit; opt-in is the default.
4. Any command created after activation must include the log-invocation step at authoring time. Command templates should include it by default.

The log-invocation step appends one entry to the adopter-declared invocation log at the end of every command run:

```
YYYY-MM-DD HH:MM UTC | /<command-name> | files_read: N | catalogue_assisted: true/false | outcome: success/fail
```

`files_read` is the count of distinct files the command opened during the run. `catalogue_assisted: true` when the command read the catalogue instead of walking the filesystem for that data.

## Related

- [`conformance/spec.md`](conformance/spec.md) — conformance agent capability spec
- [`catalogue/spec.md`](catalogue/spec.md) — catalogue agent capability spec
- [`decision-nudge/spec.md`](decision-nudge/spec.md) — decision-nudge agent capability spec
- [`observability/spec.md`](observability/spec.md) — observability agent capability spec
- [`implementations/README.md`](implementations/README.md) — runtime contract; pick an implementation or declare a custom one
- [`implementations/claude-code/spec.md`](implementations/claude-code/spec.md) — Claude Code runtime implementation
- [`implementations/github-actions/spec.md`](implementations/github-actions/spec.md) — GitHub Actions runtime implementation
