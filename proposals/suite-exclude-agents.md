---
change: suite-exclude-agents
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Suite `exclude_agents` — per-agent opt-out from the installed suite workflow

## Intent

Add an `exclude_agents` extension point to the observability suite workflow template
(`specs/observability/suite/workflow.yml`). The variable resolves to a list of agent
slugs; the template wraps each agent step in a conditional guard so that any agent whose
slug appears in `exclude_agents` is **omitted from the installed workflow file** at
adoption time. This lets an adopter who wants a subset of the data-collection agents on a
different cadence — for example, running `inbox-health` and `decision-health` in their own
daily workflow while the rest of the suite stays weekly — remove those agents from the
suite without their being silently re-added on the next `/adhere-to tooling` run. With an
empty `exclude_agents` (the default), the installed workflow contains all six agents
exactly as today.

## Rationale

**The monolithic suite is a deliberate default, not a constraint that should be
unescapable.** The suite exists so that one scheduled execution refreshes the whole
observability picture in a single commit — that coupling is the right default for most
adopters, and the spec is correct to ship it that way. But "all six agents, one schedule,
one workflow" is a *default cadence*, not a property of the agents themselves. The six
data-collection agents are independent: each reads its own inputs, writes its own file
under the observability path, and commits separately inside the suite. Nothing about
`inbox-health` requires it to run on the same clock as `spec-activity`. The current
template treats the bundle as indivisible only because there was no reason to divide it —
not because dividing it is unsound.

**Per-agent scheduling is a legitimate adopter need, and the registry data backs it up.**
The agents do not all carry the same cost or the same value-per-run. Some signals move
slowly — `spec-activity` and `contributor-activity` measure trends that are meaningless to
sample more than weekly. Others are operational: an adopter actively working a
cross-boundary collaboration wants `inbox-health` fresh daily, and an adopter in a
decision-heavy phase wants `decision-health` to keep pace. Forcing the fast-moving signals
onto the slow suite cadence either makes them stale or drags the entire (more expensive)
suite onto a faster, costlier schedule to keep one agent current. An adopter who wants two
agents daily and four weekly today has no conformant way to express that: the suite
template installs all six on one schedule, full stop.

**Without this, the only escape is a manual deviation that the standard then fights.** An
adopter can hand-edit the installed `.github/workflows/` file to delete the steps they
want elsewhere — but that edit is exactly what `/adhere-to tooling` is built to detect and
repair. The next adherence run re-renders the template from source and the deleted steps
come back, silently reverting the adopter's intentional split. The adopter is then forced
to choose between conformance (accept the monolith) and their real operating need (the
split), with the tooling actively undoing the latter. That is the precise failure mode the
standard should not create: a legitimate, well-understood need that can only be met by
fighting the conformance machinery. The fix is to make the split a **declared, sourced
extension point** so `/adhere-to tooling` renders the adopter's intent rather than
overwriting it.

**An extension point, not a fork.** The alternative — telling adopters to vendor and
maintain their own copy of the suite workflow — abandons the whole premise that the
standard ships complete, working tools that adopters extend rather than reimplement. A
forked workflow stops inheriting the guardrail fixes the suite template carries (the
write-scope hook, `git checkout -- .` before each rebase, failure logging). `exclude_agents`
keeps the adopter on the maintained template: they declare *which* agents this workflow
runs, and they continue to inherit every operational fix for the agents that remain. The
agents they excluded run in a sibling workflow the adopter authors, which is ordinary
adopter wiring — outside the standard's delta.

## Delta

This changes the suite workflow template and adds one variable to the suite workflow
artefact declaration. No change to `suite.md`'s contracts, to any individual tool spec, or
to the agents' behaviour when they do run.

### 1. `specs/observability/suite/workflow.yml` — conditional guard per agent step

Each of the six agent steps gains a guard so the step is rendered into the installed file
only when its slug is **not** in `exclude_agents`. The template already substitutes
`{{schedule}}`, `{{runner}}`, and `{{model_haiku}}` at adoption time via `/adhere-to
tooling`; `exclude_agents` is resolved the same way, and the renderer omits any guarded
step whose slug is listed.

The six guarded slugs match the existing `git config --global user.name
"observability-suite/<slug>"` line in each step:

- `owner-health`
- `inbox-health`
- `decision-health`
- `contributor-activity`
- `spec-activity`
- `risk-load`

Two properties the guard must preserve:

- **The guard is install-time, not run-time.** An excluded agent's step is *absent from the
  installed workflow file*, not present-but-skipped. This is the same install-time
  expansion model the template already uses for its substituted variables — the rendered
  artefact reflects the adopter's declaration, and `/adhere-to tooling` re-renders to the
  same shape, so an excluded agent is not re-added on the next adherence run. (A run-time
  `if:` skip would leave the step in the file, which `/adhere-to` would treat as present —
  defeating the purpose.)
- **The final write-scope validator is unconditional.** The Layer 1 post-execution
  validator (the `Validate write scope` step) runs regardless of which agents were
  rendered. Its allow-list of output filenames already covers all six agents' outputs; an
  excluded agent simply produces no diff for its file, which is within scope. The validator
  is not guarded and is not narrowed when agents are excluded.

The `if: steps.sync.outputs.DIVERGED != 'true'` sync gate on each rendered step is
unchanged — it remains on every step that *is* rendered.

### 2. Suite workflow artefact — add `exclude_agents` variable

In the artefacts block that declares the suite workflow template (the
`observability-suite-workflow` artefact, following the governance-pulse artefact pattern in
`specs/observability/governance-pulse/spec.md`), add one variable:

```yaml
- name: exclude_agents
  source: config.yaml#capabilities.observability.suite.exclude_agents
  default: []
  description: >
    List of agent slugs to omit from this suite workflow. Each listed slug's
    step is not rendered into the installed .github/workflows file. Excluded
    agents are expected to run in a sibling workflow the adopter authors.
    Valid slugs: owner-health, inbox-health, decision-health,
    contributor-activity, spec-activity, risk-load. Empty (default) renders
    all six.
```

The variable is **optional** with a `[]` default, so existing adopters who have not
declared `capabilities.observability.suite.exclude_agents` get the full six-agent workflow
unchanged. No manifest migration is required.

### 3. `specs/observability/suite.md` — document the extension point

Add `exclude_agents` to the **Extension points** table in `suite.md`:

| Extension point | Description | Default |
|---|---|---|
| Exclude agents | Agent slugs omitted from this suite workflow (run them in a sibling workflow) | `[]` (all six rendered) |

Add a short note under **Activation** (or the Tool-sequence extension-point row) clarifying
that excluding an agent removes it from *this* workflow only — the agent's tool spec,
command relay, and pull-based on-demand invocation are unaffected; the adopter is
responsible for scheduling the excluded agent elsewhere if they still want it refreshed.

This is a behaviour change to a self-contained workflow template (a step is added/removed
based on a declared value), so the implementing commit is `feat!:` per CONTRIBUTING.md —
an execution step's presence in the rendered artefact now depends on an extension-point
value.

## Acceptance scenarios

### Adopter excludes two agents — they are absent from the installed workflow

Given an adopter manifest with `capabilities.observability.suite.exclude_agents:
[inbox-health, decision-health]`
When `/adhere-to tooling` renders the suite workflow into `.github/workflows/`
Then the installed file contains the `owner-health`, `contributor-activity`,
`spec-activity`, and `risk-load` steps
And it contains no `Run /inbox-health` or `Run /decision-health` step
And the final `Validate write scope` step is present and unchanged

### Re-running `/adhere-to tooling` does not re-add excluded agents

Given the manifest above and a previously rendered workflow without the two excluded steps
When `/adhere-to tooling` runs again
Then the re-rendered workflow is byte-identical with respect to agent steps — the two
excluded agents are not re-added
And no drift is reported against the installed workflow for those agents

### Empty `exclude_agents` renders all six agents

Given an adopter who has not declared `capabilities.observability.suite.exclude_agents`
(or declares it as `[]`)
When `/adhere-to tooling` renders the suite workflow
Then the installed file contains all six agent steps in the standard order
And the result is identical to the pre-change template output

### Excluded agent still works on-demand and in its own workflow

Given `inbox-health` is in `exclude_agents`
When a contributor invokes `/inbox-health` on demand, or a sibling adopter-authored
workflow runs it
Then the agent runs normally and writes its output under the observability path
And nothing about its tool spec, command relay, or guardrails is changed by the exclusion

### Sync gate and write-scope validator preserved on rendered steps

Given any non-empty `exclude_agents` that leaves at least one agent rendered
When the suite workflow runs
Then each rendered agent step still carries `if: steps.sync.outputs.DIVERGED != 'true'`
And the unconditional final write-scope validator runs and would fail the job on any write
outside the declared observability output path

## Related

- `specs/observability/suite.md` — the suite spec; gains the `exclude_agents` extension
  point and the documentation note.
- `specs/observability/suite/workflow.yml` — the workflow template that gains the
  per-agent conditional guard.
- `specs/observability/governance-pulse/spec.md` — artefact-block + template-variable
  pattern this proposal follows for declaring `exclude_agents` as a sourced variable with a
  default.
- `proposals/observability-workflow-templates.md` — introduced the suite workflow template
  and its six sequential agent steps; this proposal makes that step set adopter-tunable.
- `proposals/install-time-expansion.md` — the install-time-expansion model the guard relies
  on: rendered artefacts reflect declared values, and `/adhere-to tooling` re-renders to the
  same shape rather than re-adding removed content.
- `CONTRIBUTING.md` — `feat!` rationale: the rendered workflow's step set now depends on an
  extension-point value.
