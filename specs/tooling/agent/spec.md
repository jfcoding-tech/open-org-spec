# Agent

**Owner:** Javier Fernandez
**Status:** Active

A standard for any automated agent running in this repo. Defines the four contracts — specification, security, implementation, and observability — that every agent must satisfy before being wired to a schedule.

## Purpose

Agents running with `--dangerously-skip-permissions` remove per-tool-call permission prompts and run unattended. Without an explicit pattern, each new agent adds its own bespoke security controls — or skips them. This spec defines the minimum set of contracts that any agent must satisfy, so the security surface and operational behaviour are predictable and auditable across all agents in the repo.

## The four contracts

Every agent must satisfy all four contracts. There are no exceptions.

---

### Contract 1 — Specification

**Two cases apply.**

**Case A — Prototype agent** (a new pattern being validated before it becomes standard): every prototype agent must have a project spec at `projects/<agent-name>/spec.md`. The project validates the pattern in practice. When the close criterion is met, the project closes and the agent logic promotes to `open-org-spec/specs/`. The project spec is the governance artefact for the prototype phase.

**Case B — Standard capability agent** (an adopter activating an agent defined by an already-graduated capability in `open-org-spec/specs/`): no project spec is required. The canonical spec in the standard replaces the project spec — the pattern has already been validated and the spec IS the governance artefact. The adopter declares the capability active in their manifest and runs the activation command; no new project is created.

The remaining Contract 1 fields apply to **Case A only**. For Case B, the write scope declaration must still be made — it lives in the adopter's manifest or extension spec rather than a project spec.

**Case A — Project spec fields** (prototype agents). Fields without defaults are required.

| Field | Requirement |
|---|---|
| `Owner` | The person accountable for the agent's behaviour |
| `Status` | Current project status (Draft / Active / Closed) |
| `Started` | ISO date the project was created (`YYYY-MM-DD`) |
| `Type` | `infrastructure` — agents are always infrastructure projects |
| Canonical spec pointer | A relative link to the spec defining the agent's logic |
| Objective | One sentence: what the agent validates or produces |
| Hypothesis | One sentence: what will be true when the agent is promoted |
| Write scope declaration | Explicit list of file paths or patterns the agent is allowed to write to. Used verbatim in the write scope validator (Contract 2, Layer 1). |
| Close criterion | Four consecutive successful weeks (four weeks of invocation log entries with `outcome: success`) |

The write scope declaration is the binding contract between the spec and the implementation. If the agent's write scope changes, the spec must be updated and the workflow regenerated before the change goes live.

**Example spec skeleton:**

```markdown
# <Agent Name>

**Owner:** <name>
**Status:** Draft
**Started:** YYYY-MM-DD
**Type:** infrastructure

**Canonical spec:** [`open-org-spec/specs/tooling/agent/spec.md`](../../open-org-spec/specs/tooling/agent/spec.md)

## Objective

<One sentence: what this agent validates or produces.>

## Hypothesis

<One sentence: what will be true when this agent is promoted.>

## Write scope

Files this agent is allowed to write to:

- `<path-pattern-1>`
- `<path-pattern-2>`

## Close criterion

Four consecutive successful weeks: four weekly invocation log entries with `outcome: success`.
```

---

### Contract 2 — Security

Every agent running with `--dangerously-skip-permissions` must implement all three of the following security layers. Layers are enforced in the runner shell; they are not optional and Claude cannot bypass them.

#### Layer 1 — Write scope validator

A post-execution shell step that diffs `git diff --name-only` against the agent's declared write scope pattern from Contract 1. Any file outside the declared scope is reverted and the step exits with code 1, blocking the push.

```bash
UNEXPECTED=$(git diff --name-only | grep -vE '<write-scope-pattern>' || true)
if [ -n "$UNEXPECTED" ]; then
  echo "SECURITY: agent wrote to unexpected files:"
  echo "$UNEXPECTED"
  git checkout -- $UNEXPECTED
  exit 1
fi
```

The `<write-scope-pattern>` is a regex derived directly from the write scope declaration in the project spec. It is declared once in the spec and referenced in the workflow — never invented separately.

This layer is enforced by the runner, not by the model. It limits the blast radius of any model-generated output that attempts to write outside the declared scope, whether from a prompt injection attempt, a model error, or a guardrail failure.

#### Layer 2 — Sparse checkout

The `actions/checkout@v4` step must use the `sparse-checkout:` key, scoped to only the paths the agent legitimately reads and writes. Files outside the sparse checkout do not exist in the working tree. Claude cannot read or modify them regardless of what the model generates.

```yaml
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      <read-path-1>
      <read-path-2>
      <write-path-1>
```

The sparse checkout paths are declared in the project spec's write scope declaration plus any additional read paths the agent requires.

#### Layer 3 — Prompt guardrails

A mandatory preamble injected before the agent's task prompt in the workflow step. The preamble declares three constraints:

```
WRITE SCOPE: You may only write to the following paths: <write-scope-from-spec>.
Any write outside this scope is a violation — stop and report it instead of proceeding.

NO FABRICATION: Extract information only from the files you read.
Do not guess, infer, or generate content that is not present in the source material.
If a required field is missing from a source file, note the gap and skip that entry.

EXIT ON UNCERTAINTY: If you are uncertain whether an action is within scope,
do not proceed. Append one line to <warnings-file> describing what you were uncertain about,
then stop.
```

The `<write-scope-from-spec>` is copied verbatim from the project spec's write scope declaration. The `<warnings-file>` is the adopter-declared warnings file (see adopter wiring).

Guardrails are injected in the workflow step before the agent prompt, so they are always present regardless of what the command file contains.

---

### Contract 3 — Implementation

Every agent must have a GitHub Actions workflow at `.github/workflows/<agent-name>.yml` that satisfies all of the following requirements:

| Requirement | Detail |
|---|---|
| Permissions | `permissions: contents: write` |
| Runner | Adopter-declared runner (see adopter wiring) |
| Checkout | `actions/checkout@v4` with `sparse-checkout:` scoped per Contract 2 Layer 2 |
| Write scope validator | Shell step after agent execution, per Contract 2 Layer 1 |
| Prompt guardrails | Preamble injected before agent prompt, per Contract 2 Layer 3 |
| Manual trigger | `on: workflow_dispatch` for manual runs and re-runs |
| Retry loop | `git pull --rebase` before each push attempt; max 3 attempts; 30-second sleep between attempts |
| LLM gateway | `ANTHROPIC_BASE_URL` set to the adopter-declared gateway |
| Model | `--model <adopter-declared model>` |
| Permissions flag | `--dangerously-skip-permissions` |
| System prompt | `--system-prompt "<agent-stub>"` — pass the agent context stub as a CLI flag. Never overwrite `CLAUDE.md` to manage agent context. `CLAUDE.md` is a shared governance artefact; overwriting it corrupts the repo for subsequent runs and human sessions. The `--system-prompt` flag replaces the CLAUDE.md context for the agent session without touching the file. |
| Frontmatter strip | Strip YAML frontmatter from command files before passing to `claude -p` |
| Job timeout | `timeout-minutes: 30` |

**Retry loop structure:**

```bash
ATTEMPT=1
MAX_ATTEMPTS=3
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  git pull --rebase
  claude -p "$PROMPT" \
    --model "$MODEL" \
    --dangerously-skip-permissions \
    2>&1
  # [write scope validator step here]
  if git push; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -le $MAX_ATTEMPTS ]; then
    sleep 30
  fi
done
if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
  echo "$(date -u '+%Y-%m-%d %H:%M') UTC | /<agent-name> | attempt ${MAX_ATTEMPTS} failed: push exhausted" >> "$FAILURE_LOG"
  exit 1
fi
```

**Frontmatter strip:**

YAML frontmatter (`---` ... `---`) must be stripped from command files before they are passed to `claude -p`. Many command files carry `description:` and `owner:` headers that are not instructions for Claude; passing them unstripped produces noisy or incorrect agent behaviour.

```bash
COMMAND_CONTENT=$(sed '/^---$/,/^---$/d' .claude/commands/<agent-name>.md)
PROMPT="$GUARDRAILS_PREAMBLE

$COMMAND_CONTENT"
```

---

### Contract 4 — Observability

Every agent must produce structured log entries on every run.

#### Invocation log entry

Appended to the adopter-declared invocation log on every run (success or failure):

```
- YYYY-MM-DD HH:MM UTC | /<agent-name> | files_read: N | catalogue_assisted: true/false | outcome: success/fail | spec_version: <version>
```

| Field | Meaning |
|---|---|
| `YYYY-MM-DD HH:MM UTC` | UTC timestamp of the run |
| `/<agent-name>` | The agent's command name, matching the command file |
| `files_read: N` | Count of distinct files the agent read during the run |
| `catalogue_assisted: true/false` | `true` when the agent read the catalogue rather than walking the filesystem; `false` when it walked directly |
| `outcome: success/fail` | `success` on a clean push; `fail` on any non-recovered error |
| `spec_version: <version>` | The `canonical_spec_version` from the command's frontmatter. Present only for self-contained commands (those with a `canonical_spec` field). Omitted for interactive commands and for commands without a declared canonical spec. Enables retrospective drift detection — the log shows exactly which version of the spec each run executed against. |

#### Failure log entry

Appended to the adopter-declared failure log on max-retry exhaustion only:

```
- YYYY-MM-DD HH:MM UTC | /<agent-name> | attempt <N> failed: <reason>
```

The failure log is kept separate from the invocation log so failures are easy to find without filtering by outcome.

Both log entries are written and committed by a shell step in the workflow, not by the agent itself. This ensures the log entries are present even when the agent produces no output or exits early.

---

## Backlog

### B-001 — Guardrails as the default assumption for `--dangerously-skip-permissions`

Currently, guardrails (write scope, no fabrication, exit on uncertainty) are added per-agent as an explicit implementation step. This should be inverted: any agent running with `--dangerously-skip-permissions` should get all three guardrails by default, with the option to declare additional agent-specific constraints on top.

**What to change:**

1. The agent-creation command should scaffold all three guardrail types automatically, with the write scope filled in from the contributor's input. No agent should be created without them.
2. The activation check (run before wiring any agent to a schedule) should verify all three guardrail types are present in the workflow. If any is absent, activation should refuse and point to the missing layer.
3. The agent spec template (Contract 1) should include the guardrails preamble in its checklist, so the reviewer confirms their presence before approving the workflow.

**Resolves when:** the agent-creation command enforces all three guardrail types automatically and this agent spec is in the standard.

---

## Related

- [`../spec.md`](../spec.md) — tooling capability overview
- [`../spec-health/spec.md`](../spec-health/spec.md) — spec-health suite; the reference implementation of this pattern
