---
change: catalogue-edges-graph
status: proposed
opened: 2026-07-22
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: Catalogue edges — typed relationship graph for specs

## Intent

Extend the `catalogue` capability with a new sub-catalogue, `edges.yaml`, that
captures the structural relationships between specs — today expressed only as
untyped prose in each spec's `## Related` / `## Dependencies` section — as
queryable data. A companion read-only query capability answers reverse-lookup
("what references X") and blast-radius ("what depends on X, directly or
transitively") questions in one read, instead of a contributor or agent
re-deriving the relationship graph by grep/glob/Read every time.

This proposal does **not** commit to shipping the feature yet. Its immediate
ask is authorisation to validate the approach as a prototype project (per
Contract 1 Case A, [`specs/tooling/agent/spec.md`](../specs/tooling/agent/spec.md))
in an adopter repository, comparing the graph-backed approach against the
status quo (grep/glob/Read) on a fixed benchmark before any spec delta is
written. Promotion to an actual `catalogue` extension is contingent on that
comparison.

## Rationale

**The relationships already exist — as prose, not data.** Every capability
spec in this standard ends with a hand-maintained `## Related` section
declaring its connections to other specs: hard requirements (`risk-at-scope`
requires `feedback-inbox` active), optional/graceful-degradation dependencies
(`observability`'s owner-health metrics "degrade gracefully… reading role
headers verbatim" when `people` is inactive), companion pairs
(`governance-at-scope` / `people` — "who decides here?" vs. "who is here?"),
and planned-but-not-yet-built edges (`project`'s Related section: `adherence-check`
"will validate conformance of project specs once extended to cover the
`project` capability"). None of this is validated or queryable today; it is
trusted by convention.

**This produces real, checkable drift.** `specs/roles/spec.md`'s `## Related`
section links to `../../proposals/teams.md` and
`../../proposals/working-agreement.md`. Neither file exists any more — both
proposals were promoted and moved to `proposals/closed/`, with their live
content now at `specs/teams/spec.md` and `specs/working-agreement/spec.md`.
That is a dead link sitting in the standard's own normative content right now,
undetected because nothing checks `## Related` links against the filesystem.

**This is the same problem CodeGraph solves for source code, applied to
markdown specs instead of function calls.** CodeGraph's premise is that an
agent answering a structural question ("what calls this function", "what
breaks if I change this") should not have to rediscover the answer via
grep/glob/Read every time — a pre-built graph answers it in one call. This
standard's own specs have the same shape of problem (structural
cross-references an agent currently re-derives by walking prose) at a much
smaller scale (tens of specs, not thousands of files), which is exactly why
this should start as a lightweight prototype rather than adopting CodeGraph's
own architecture (a Rust/tree-sitter kernel, a SQLite+FTS5 database, a
file-watcher) wholesale — that machinery solves a scale and parsing problem
this standard does not have.

**Fog-of-war: start with one untyped edge, not a full taxonomy.** A `requires`
/ `optional` / `companion` / `governs` typed model is more expressive but
requires either a new authoring convention or fuzzy prose-parsing, both more
failure-prone than the minimal version. The first cut derives a single
generic `references` edge verbatim from existing `## Related` links — zero new
convention for contributors to learn — and already unlocks the two things
that matter most: reverse lookup and stale-link detection. Typed edges are a
second iteration, added only if `references` alone proves too coarse in
practice.

**Validate before building scheduled infrastructure.** `catalogue`'s daily
regeneration, split-file output, and handler-registration mechanism are real
infrastructure with a real maintenance cost. Building an `edges.yaml` handler,
wiring it into the daily walk, and writing a query tool against it — before
confirming a graph-backed query actually beats grep/glob/Read on real
questions — risks shipping infrastructure nobody needed. The prototype
therefore computes its graph **on the fly** at query time (reads
`## Related`/`## Dependencies` sections across the target spec tree, builds an
in-memory adjacency, answers the question, discards it) with no dependency on
`catalogue`'s scheduled pipeline. If the benchmark validates the approach, the
optimisation is swapping "walk at query time" for "read pre-generated
`edges.yaml`" — a performance change to an already-proven command, not a
prerequisite for testing it.

## Delta

**If validated, this promotes as:**

- A new handler on the `catalogue` capability
  ([`specs/tooling/catalogue/spec.md`](../specs/tooling/catalogue/spec.md)),
  following the existing handler-registration pattern (`collect` /
  `output_schema` / `output_path`), emitting `edges.yaml` alongside
  `specs.yaml` / `decisions.yaml` / `scopes.yaml`.
- A companion read-only query tool spec (shape TBD — either folded into an
  existing tool or a new one under `specs/tooling/`), promoted only once a
  second consumer wants the same query shape, mirroring how `catchup` and
  `catalogue` themselves were extracted to standalone specs after validation,
  not speculatively up front.

**Nothing in this delta ships with this proposal.** The proposal's actual
deliverable at this stage is the prototype validation plan below, run against
an adopter repository, not a change to any spec under `specs/`.

## Prototype validation plan

### Project scaffold (Contract 1 Case A)

The prototype runs as a project in the **adopter** repository being tested
against — not in this repo, which is the standard itself and does not host
`projects/` (per [`specs/project/spec.md`](../specs/project/spec.md): project
artefacts are adopter-side operational content, not normative content of the
standard). Scaffold `projects/catalogue-edges/spec.md` there with:

```markdown
# Catalogue Edges — prototype

**Owner:** <contributor name>
**Status:** Draft
**Started:** <YYYY-MM-DD>
**Type:** infrastructure

**Canonical spec:** open-org-spec/proposals/catalogue-edges-graph.md
(this proposal, read via the submodule pinned to the `catalogue-edges-graph`
branch of the fork under test)

## Objective

Validate whether an on-the-fly relationship-graph query beats grep/glob/Read
on real structural questions against this repo's active specs, on
cost (tool calls, files read, tokens, time) and correctness (recall,
precision, stale-link detection).

## Hypothesis

The graph-backed query answers reverse-lookup, blast-radius, and stale-link
questions in fewer tool calls and tokens than the grep/glob/Read baseline,
with equal or better recall and precision, and is the only approach of the
two that reliably answers multi-hop (transitive) questions.

## Write scope

- `projects/catalogue-edges/**` only.

## Close criterion

Not the default four-consecutive-weeks (this is a one-off validation, not a
scheduled agent). Close criterion: the benchmark comparison in
`projects/catalogue-edges/benchmark/results.md` is complete for every
question in `questions.yaml`, with a written recommendation (promote /
iterate / abandon).

## Success metrics

Distinct from the close criterion (did the comparison run to completion) —
these decide *what* the recommendation should be. Each question runs N=3
times per arm; judge against the median, not a single favourable run.

1. **Correctness floor (must-pass).** Graph-backed recall = 100% and
   precision ≥ baseline's on every `VERIFIED`-ground-truth question.
   `stale-01` specifically: graph-backed must catch both dead links in
   `roles/spec.md`. Failing this means nothing else below matters.
2. **The discriminating criterion.** On `transitive-01`, the graph-backed
   approach must succeed where the baseline either fails outright or needs
   materially more tool calls/turns for the same answer. This is the
   proposal's actual thesis (multi-hop reasoning, not single-hop lookup) —
   if the baseline performs comparably here too, the premise is weaker than
   argued regardless of how the easier questions score.
3. **Efficiency bar (supporting, not sufficient alone).** On the single-hop
   questions (`reverse-01`, `typed-01`, `gap-01`), graph-backed `tool_calls`
   and `tokens` are lower than baseline by ≥40% — a marginal win doesn't
   justify the maintenance cost this proposal's own Rationale argues
   against incurring prematurely.
4. **Precision bar.** On `precision-01`, baseline's naive-grep precision is
   ~28% (7 real edges out of ~25 string hits). Graph-backed should approach
   100%, since it only reports declared `## Related` edges.

**Decision rule.** Promote only if 1 and 2 both hold; 3 and 4 are supporting
evidence, not sufficient alone. If 2 fails while 1/3/4 hold, that is
"iterate" (a cheaper single-hop-only version might still be worth it), not
"promote" as currently scoped.
```

### Benchmark question schema

`projects/catalogue-edges/benchmark/questions.yaml`. Below is the seed set
verified against **this standard's own specs** — usable as-is when testing
against a repo that vendors `open-org-spec`, or as a worked example when
generating an adopter-specific set (see the discovery guide below).

```yaml
- id: stale-01
  type: stale-link
  question: >
    Does specs/roles/spec.md's ## Related section point to any files
    that no longer exist at the linked path?
  target: specs/roles/spec.md
  ground_truth: VERIFIED
  expected_answer: >
    Yes — 2 dead links. ../../proposals/teams.md (moved to
    proposals/closed/teams.md; live content now at specs/teams/spec.md)
    and ../../proposals/working-agreement.md (moved to
    proposals/closed/working-agreement.md; live content now at
    specs/working-agreement/spec.md).

- id: reverse-01
  type: reverse-lookup (single-hop)
  question: >
    Which capability specs declare feedback-inbox as a dependency in
    their ## Related or ## Dependencies section?
  target: specs/feedback-inbox/spec.md
  ground_truth: VERIFIED
  expected_refs:
    - specs/tooling/catchup/spec.md
    - specs/roles/spec.md
    - specs/working-agreement/spec.md
    - specs/governance-at-scope/tools/scope-elevation/spec.md
    - specs/risk-at-scope/spec.md
    - specs/adoption-manifest/spec.md
    - specs/observability/spec.md

- id: typed-01
  type: typed-edge (required vs optional)
  question: >
    Which capabilities depend on people only optionally — i.e. explicitly
    degrade gracefully without it, rather than requiring it?
  target: specs/people/spec.md
  ground_truth: VERIFIED
  expected_refs:
    - specs/observability/spec.md
    - specs/scope-registry/spec.md

- id: gap-01
  type: coverage-gap
  question: >
    Which capability has an adherence-check validation target explicitly
    planned in its spec but not yet built?
  target: specs/adherence-check/spec.md
  ground_truth: VERIFIED
  expected_answer: >
    project — "will validate conformance of project specs once extended
    to cover the project capability."

- id: transitive-01
  type: transitive blast-radius (multi-hop)
  question: >
    If feedback-inbox's entry format changed, which capabilities would
    be affected only indirectly — they don't mention feedback-inbox
    themselves, but depend on something that does?
  target: specs/feedback-inbox/spec.md
  ground_truth: TO CONFIRM AT RUN TIME
  note: >
    Requires walking the chain (e.g. anything requiring risk-at-scope or
    working-agreement inherits the exposure without saying
    "feedback-inbox" anywhere in its own text). Deliberately the hardest
    question — designed to separate single-hop grep from real traversal.

- id: precision-01
  type: precision (false-positive check)
  question: >
    Of all files containing the literal string "feedback-inbox", how
    many are real structural dependencies (declared in ## Related) vs.
    incidental mentions (changelog notes, backlog entries, prose asides)?
  target: feedback-inbox
  ground_truth: VERIFIED
  expected_answer: >
    ~25 files contain the string; only the 7 in reverse-01 are declared
    structural edges. The rest (backlog.md, proposals/aims.md,
    proposals/progress-log.md, several proposals/closed/*.md) are
    incidental or historical mentions, not live dependencies.

- id: hub-01
  type: aggregate / hub-ranking
  question: >
    Which capability has the most inbound structural references across
    all specs — i.e. is riskiest to change without checking dependents?
  ground_truth: TO CONFIRM AT RUN TIME
  note: >
    feedback-inbox is the leading candidate (18 raw inbound hits under
    specs/) ahead of people and governance-at-scope, but needs a
    consistent same-filter recount before locking in as ground truth.
```

**Methodology note.** For single-hop questions (e.g. `reverse-01`), plain
grep on the literal string will likely match on *recall* too, since it is a
full-text search. The graph's edge there is efficiency (one read vs. N
grep/read cycles) and precision (`precision-01` — filtering real edges from
incidental mentions), not recall alone. `transitive-01` is the question type
where grep has no mechanism to succeed without already knowing what to search
for next — weight the benchmark so it is not dominated by the easy, single-hop
case, or the comparison will understate the graph's actual advantage.

### Discovery guide (for generating an adopter-specific question set)

When testing against a different adopter repo (not this standard's own
specs), generate its `questions.yaml` first rather than reusing the seed set
verbatim — most of it should reflect the adopter's real content. Run this as
a read-only discovery pass:

```
You are surveying <adopter-repo> to generate benchmark questions for a
comparison test (grep/glob/Read baseline vs. a relationship-graph-backed
query). Read-only: do not write, stage, commit, or push anything.

Step 1 — Confirm scope
Read .open-org-spec/config.yaml. List active capabilities and any
declared tool_extensions. Only draw questions from capabilities that
are actually active here.

Step 2 — Inventory relationship-bearing files
Walk and list every file that carries a ## Related, ## Dependencies,
## How You Work With Your Peers, or equivalent cross-reference section:
governance folders (decisions/, working-agreements), people.md / role
specs (peer tables), feedback.md entries with addressee markers, risk
records (scope: references, affects:/supersedes:), team specs
(dotted-line relationships), project specs, the standard's own specs/
(if vendored) plus any adopter extensions.

Step 3 — Generate one candidate question per category
1. STALE-LINK — a relative link whose target path no longer exists.
   Prioritise files near recently closed/promoted projects or decisions.
2. REVERSE-LOOKUP (single-hop) — every file naming a frequently
   referenced artefact in a structural section.
3. TYPED-EDGE — a pair where the relationship is explicitly
   optional/companion/degrades-gracefully rather than a hard
   requirement (the wording usually says so directly).
4. COVERAGE-GAP — a check, integration, or validation declared as
   "planned" / "once extended" / "not yet" — a declared-but-missing edge.
5. TRANSITIVE (multi-hop) — two relationships that chain, where the
   first artefact never mentions the third by name.
6. PRECISION — a term appearing often in prose; separate real
   structural references from incidental mentions.
7. HUB-RANKING — count inbound structural references per artefact;
   name the top 1-2.

If real org data exists (decisions, risks, working-agreements, role
peer tables), also generate:
8. REORG BLAST-RADIUS — a real person or team; every decision, risk,
   working-agreement, and role peer table that names them.
9. AGREEMENT NETWORK — a scope with a working-agreement; its full set
   of formalised peers, direct and via dotted-line teams.

Step 4 — Write ground truth by hand
Do not trust your own discovery pass as the answer key. Re-derive the
expected answer by manually opening and reading each relevant file a
second time, independently. Flag anything you are not fully confident
in as "TO CONFIRM" rather than asserting it.

Step 5 — Output
Emit results in the questions.yaml shape above: id, type, question,
target, ground_truth (VERIFIED / TO CONFIRM), expected_refs or
expected_answer, note.
```

### Guided run — step-by-step agent instructions

Run interactively, not autonomously — a human confirms each step, because
ground truth in Step 4 above must be hand-verified, not trusted from a single
pass.

```
Work through this step by step. After each step, stop, show me what you
found or produced, and wait for me to say "continue" before moving on.
Do not run ahead to later steps on your own.

Step 0 — Create the disposable test branch.
git status first — confirm the working tree is clean and we're on the
default branch before branching. Then git checkout -b test/catalogue-edges.
Confirm with git branch --show-current. Everything from here on happens
on this branch only; it is never merged into the adopter's default branch.

Step 1 — Point the submodule at the prototype branch.
Inside open-org-spec/, add or reuse a remote pointing at the fork
(jfcoding-tech/open-org-spec) — ask which remote name/URL/auth to use if
not already configured. Fetch it, then git checkout catalogue-edges-graph.
Show git log -1 and git status for the submodule to confirm before
continuing. Do not commit the resulting gitlink change in the adopter
repo's own index.

Step 2 — Read the design.
Read open-org-spec/proposals/catalogue-edges-graph.md. Summarise it back
in a few sentences to confirm shared understanding before scaffolding
anything.

Step 3 — Scaffold the project.
Draft projects/catalogue-edges/spec.md per Contract 1 Case A (project
scaffold above). Show the draft. Do not write it to disk until confirmed.

Step 4 — Generate benchmark questions.
Follow the discovery guide above against this repo's own active
capabilities and content (or reuse the seed set if testing against
open-org-spec's own specs). For each candidate question, show the
question, its type, the proposed ground truth, and confidence (verified
by re-reading the source a second time, or "to confirm"). Wait for
sign-off on each before adding it to
projects/catalogue-edges/benchmark/questions.yaml.

Step 5 — Run the comparison.
Use claude-sonnet-5 for every step, including both arms of the
comparison — the two arms must run on the same model or the comparison
is confounded. One question at a time: run the baseline (grep/glob/Read
only, no graph tool) and the graph-backed version, report tool_calls,
distinct_files_read, tokens, duration_s, recall, precision, and
stale_detected for both, then pause before the next question. If not
confident in a proposed ground truth from Step 4, flag it for a manual
Opus check rather than guessing. Append each result to
projects/catalogue-edges/benchmark/results.md.

Step 6 — Summarise.
Show the full comparison table and a recommendation (promote / iterate /
abandon). Do not decide or commit anything — just report.

Constraint throughout: read/write/commit only within
projects/catalogue-edges/ (plus the open-org-spec/ submodule, read-only),
and only on the test/catalogue-edges branch. Nothing else gets touched,
and nothing gets committed, pushed, or merged without explicit go-ahead.
```

## Acceptance scenarios

### Stale-link question is answered correctly

Given the prototype project scaffolded per Contract 1 Case A in an adopter
repo whose `open-org-spec/` submodule is pinned to this proposal's branch
When the graph-backed prototype answers `stale-01`
Then it identifies both dead links in `specs/roles/spec.md`'s `## Related`
section and names their current locations

### Comparison table exists for every question

Given the benchmark question set (seed or adopter-generated) with all ground
truth confirmed per Step 4
When the guided run completes Step 5 for every question
Then `projects/catalogue-edges/benchmark/results.md` contains, for each
question, both arms' `tool_calls`, `distinct_files_read`, `tokens`,
`duration_s`, `recall`, `precision`, and `stale_detected` values

### Transitive question discriminates the two approaches

Given `transitive-01` (or its adopter-specific equivalent) run under both
the baseline and the graph-backed prototype
When the results are compared
Then the comparison explicitly states whether the baseline located the
indirect dependency, and if not, identifies at what point the grep-based
exploration stopped short

### Promotion decision is recorded, not implied

Given a completed comparison table
When Step 6 produces its recommendation
Then the recommendation (promote / iterate / abandon) is written into
`results.md` with the reasoning, and if "promote," names what changes before
this proposal's Delta section can be written as a real spec change

## Decision authority

This proposal produces a recommendation, not a committed direction — the
prototype's own hypothesis may be refuted. The standard author (Javier
Fernandez) decides whether to proceed to a `feat:` promotion, iterate the
prototype, or abandon it, based on the completed benchmark comparison.

## Related

- [`../specs/tooling/catalogue/spec.md`](../specs/tooling/catalogue/spec.md) — the capability this would extend; the handler-registration pattern this proposal reuses.
- [`../specs/tooling/agent/spec.md`](../specs/tooling/agent/spec.md) — Contract 1 Case A, which governs the prototype's project-spec shape and write-scope declaration.
- [`../specs/roles/spec.md`](../specs/roles/spec.md) — source of the verified stale-link benchmark case (`stale-01`).
- [`../specs/project/spec.md`](../specs/project/spec.md) — confirms project artefacts are adopter-side operational content, which is why the prototype runs in an adopter repo rather than here.
- [`../backlog.md`](../backlog.md) — "Prototype interactive commands: read-only default, no command-directory wiring until graduation" (added 2026-07-22), surfaced while scoping this prototype's execution model.
