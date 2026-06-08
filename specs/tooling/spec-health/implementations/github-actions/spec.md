# Spec-Health: GitHub Actions Implementation

**Owner:** Javier Fernandez
**Status:** Active

The GitHub Actions runtime implementation for the spec-health suite. Satisfies the three shared contracts (scheduling, retry, observability) using GitHub Actions workflows and a model API. Concrete workflow structure and shell mechanisms are described here; they are absent from the capability specs.

## How it satisfies the shared contracts

### Scheduling contract — `on: schedule`

Two deployment patterns are supported. Choose based on whether the agents can run independently.

**Pattern A — Separate workflows (default)**

Each agent has its own workflow file and cron schedule. Suitable when the timing gap between runs is sufficient for the first agent to commit before the second starts (typically 30+ minutes for conformance → catalogue).

| Agent | Workflow file | Cron expression |
|---|---|---|
| conformance | `.github/workflows/spec-health-conformance.yml` | adopter-declared conformance schedule |
| catalogue | `.github/workflows/spec-health-catalogue.yml` | adopter-declared catalogue schedule |

**Pattern B — Sequential steps in one workflow (recommended for conformance → catalogue)**

Both agents run as sequential steps in a single workflow file. The catalogue step starts only after the conformance step has committed its outputs — guaranteeing the dependency without relying on timing. This is the preferred pattern when the two schedules are within the same hour, because it eliminates any risk of catalogue starting while conformance is still committing.

```yaml
# .github/workflows/spec-health.yml
on:
  schedule:
    - cron: '<adopter-declared schedule>'
steps:
  - name: Run /conformance
    run: |
      # ... run conformance, commit, push
  - name: Run /catalogue
    run: |
      git pull --ff-only || true   # pick up conformance's commit
      # ... run catalogue, commit, push
```

Each step sets its own `git config user.name` (`spec-health/conformance` and `spec-health/catalogue` respectively) before running, so commits remain attributable per agent.

The `decision-escalation` and `agent-metrics` agents are no longer part of this suite (they moved to `governance-at-scope` tooling and the tooling capability respectively). Adopters who run them via GitHub Actions wire their workflows from those capabilities' own implementations, not here.

### Retry contract — shell loop with sleep

**Before any write:** the workflow step runs `git pull --ff-only`. On non-zero exit, treat as push-risk: do not proceed. Set a retry flag and continue to the retry logic.

**Retry loop structure:**

```bash
ATTEMPT=1
MAX_ATTEMPTS=3
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  # ... agent execution and git push ...
  if git push; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
    sleep 480
  fi
done
if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
  # write failure entry to failure log
  echo "$(date -u '+%Y-%m-%d %H:%M') UTC | <agent> | attempt ${MAX_ATTEMPTS} failed: push exhausted" >> "$FAILURE_LOG"
  exit 1
fi
```

The retry counter is passed to the model API call as an environment variable (`ATTEMPT_NUMBER`) so the agent prompt heading can carry it.

**Delay:** 480 seconds (`sleep 480`) between attempts. This matches the Claude Code implementation's delay for consistency.

### Observability contract — shell append

The workflow step appends an invocation log entry to the adopter-declared invocation log file using a shell `echo` command:

```bash
echo "$(date -u '+%Y-%m-%d %H:%M') UTC | <agent> | files_read: $FILES_READ | catalogue_assisted: $CATALOGUE_ASSISTED | outcome: $OUTCOME" >> "$INVOCATION_LOG"
```

This append is followed by a `git add`, `git commit`, and `git push` to persist the entry alongside any agent output. If the git push fails at this point, the retry logic above applies.

## Agent execution

Each workflow installs `curl` and `jq` at runtime, then calls the adopter-declared LLM gateway directly:

**Install step:**
```yaml
- name: Install dependencies
  run: apt-get install -y curl jq
```

**Agent call step:**
```bash
RESPONSE=$(curl -s <adopter-declared LLM gateway>/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{
    \"model\": \"<adopter-declared model>\",
    \"max_tokens\": 8096,
    \"messages\": [{
      \"role\": \"user\",
      \"content\": $(cat <adopter-declared agent prompt file> | jq -Rs .)
    }]
  }")

# Extract text from response
OUTPUT=$(echo "$RESPONSE" | jq -r '.content[0].text // empty')
```

The response is the agent's full output. File writes and git operations are performed by shell commands in subsequent workflow steps, guided by the agent output.

The agent prompt heading carries the retry counter:

```
# <Agent Name> — attempt $ATTEMPT_NUMBER of $MAX_ATTEMPTS
```

### Alternative: agentic CLI execution

Adopters who need the model to use tools (file reads, edits, shell commands) may use
`claude -p` (or an equivalent agentic CLI) instead of `curl`. The tradeoff: the CLI
reads the adopter's contributor guide (`CLAUDE.md` or equivalent) from the working
tree, which instructs the agent to load capability specs at session start — adding
context overhead for agents with a fixed, narrow task.

**Required mitigation:** add a step immediately before each agentic CLI call that
replaces the contributor guide with a minimal agent stub:

```yaml
- name: Replace contributor guide with agent stub
  run: |
    echo "# Agent mode — governance enforced via workflow guardrails and hooks." \
    > <contributor-guide-path>
```

Where `<contributor-guide-path>` is the adopter's contributor guide path (e.g. `CLAUDE.md`
for Claude Code). The stub eliminates startup spec-loading overhead while preserving
interface-level hooks (e.g. `.claude/settings.json` PreToolUse hooks for write-scope
enforcement) — hooks fire on tool calls, not on contributor guide content. The stub
exists only in the working tree during the agent run; it is never committed.

## File and version control operations

| Operation | Mechanism |
|---|---|
| Read spec files, logs, catalogue | `cat`, `find`, `grep` shell commands |
| Write catalogue, log entries, nudge entries | `echo` or `tee -a` shell commands |
| `git pull --ff-only` | git CLI |
| Last-edited date for a file | `git log -1 --format="%ai" -- <path>` |
| `git add`, `git commit`, `git push` | git CLI |

Push authentication (deploy key, token, or SSH key) is an adopter-declared concern. The adopter declares the credential and the push remote in their wiring layer.

## Runner

The runner each workflow runs on is an adopter-declared concern, declared via `runs-on:`. The runner must provide:

- Outbound HTTPS to the adopter-declared LLM gateway
- A means to install `curl` and `jq` at runtime (or have them pre-installed)
- Git with push access to the repo

## Security

Running agents with `--dangerously-skip-permissions` removes per-tool-call permission prompts. Two compensating controls are required for any GitHub Actions implementation of the spec-health suite.

### Layer 1 — Post-execution write scope validator

After the agent runs and before the push, a shell step validates that the agent only modified files within the agent's declared write scope. Any file outside the scope is reverted and the step fails, blocking the push.

```bash
UNEXPECTED=$(git diff --name-only | grep -vE '<allowed-pattern>' || true)
if [ -n "$UNEXPECTED" ]; then
  echo "SECURITY: agent wrote to unexpected files:"
  echo "$UNEXPECTED"
  git checkout -- $UNEXPECTED
  exit 1
fi
```

The allowed pattern is declared per agent by the adopter. Adopters must declare their own per-agent write scope patterns at activation time.

This layer is enforced in the runner shell — the agent cannot bypass it regardless of what the model generates.

### Layer 2 — Sparse checkout

Each agent checks out only the paths it legitimately reads or writes. Files outside the sparse checkout do not exist in the working tree, so the agent cannot read or modify them even if it attempts to.

Sparse checkout is declared in the `actions/checkout@v4` step via the `sparse-checkout:` key. Each agent's checkout is scoped to its read paths plus its write paths. The per-agent sparse-checkout paths are declared by the adopter.

### What these layers do not protect against

- A compromised model API key or LLM gateway
- Malicious content injected into repo files that the agent reads (prompt injection from untrusted file content — see note below)
- Failures in the runner's shell environment itself

**Prompt injection note:** agents read repo files as part of their task. A contributor could embed instructions in a spec or feedback file that attempt to redirect the agent's behaviour. The write scope validator (Layer 1) limits the blast radius — even if the agent is redirected, it cannot write outside its declared scope.

## Activation in the manifest

```yaml
capabilities:
  spec-health:
    status: active
    implementation: github-actions
```

After adding this entry, add the workflow file(s) under `.github/workflows/` following the chosen pattern. For Pattern B (sequential), declare `deployment_pattern: sequential` in the spec-health manifest entry so `/spec-health-activate` and `adhere-to` scaffold the combined workflow instead of two separate ones.

## Artefacts

Workflow artefacts for the `github-actions` implementation. Pattern A (separate workflows) scaffolds two files; Pattern B (sequential) scaffolds one. Both patterns carry the same `condition` — they scaffold only when `implementation: github-actions` is declared. The cron schedule, gateway, model, runner, and manifest_dir are substituted from adopter wiring.

```yaml
artefacts:
  - id: workflow-conformance
    type: file
    path: ".github/workflows/spec-health-conformance.yml"
    template: specs/tooling/spec-health/implementations/github-actions/workflows/spec-health-conformance.yml
    variables:
      - name: cron_schedule
        source: config.yaml#capabilities.spec-health.agents.conformance.schedule
      - name: llm_gateway
        source: config.yaml#capabilities.spec-health.llm_gateway
      - name: model
        source: config.yaml#capabilities.spec-health.model
      - name: runner
        source: config.yaml#capabilities.spec-health.runner
      - name: manifest_dir
        source: standard#manifest_dir
    check:
      type: file_exists
    condition:
      type: config_equals
      config_path: capabilities.spec-health.implementation
      equals: github-actions

  - id: workflow-catalogue
    type: file
    path: ".github/workflows/spec-health-catalogue.yml"
    template: specs/tooling/spec-health/implementations/github-actions/workflows/spec-health-catalogue.yml
    variables:
      - name: cron_schedule
        source: config.yaml#capabilities.spec-health.agents.catalogue.schedule
      - name: llm_gateway
        source: config.yaml#capabilities.spec-health.llm_gateway
      - name: model
        source: config.yaml#capabilities.spec-health.model
      - name: runner
        source: config.yaml#capabilities.spec-health.runner
      - name: manifest_dir
        source: standard#manifest_dir
    check:
      type: file_exists
    condition:
      type: config_equals
      config_path: capabilities.spec-health.implementation
      equals: github-actions
```

## Notes

- **API key:** The model API key is passed as the `x-api-key` header in the curl call. Store as a GitHub Actions secret (e.g. `ANTHROPIC_API_KEY`).
- **Runtime dependencies:** `curl` and `jq` are installed via `apt-get` at the start of each workflow run, or pre-installed on the runner.
- **Push authentication:** the credential and remote are adopter-declared. Do not assume `GITHUB_TOKEN` works — many branch configurations reject it.
- **Job timeout:** set `timeout-minutes: 30` in each workflow — agents that walk large repos should not run unbounded.
- **Model version:** pin to the current recommended model at activation time and update when models retire.
- **One workflow per agent:** keeping workflows separate means a failure in one agent does not block the others, and each can be triggered or re-run independently from the Actions UI.

## Related

- [`../README.md`](../README.md) — runtime contract; three shared contracts any implementation must satisfy
- [`../../spec.md`](../../spec.md) — suite capability spec; abstract contracts
- [`../../conformance/spec.md`](../../conformance/spec.md) — conformance agent capability spec
- [`../../../catalogue/spec.md`](../../../catalogue/spec.md) — catalogue capability spec (standalone)
