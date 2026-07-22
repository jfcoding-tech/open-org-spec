# open-org-spec — backlog

Deferred work against the open-org-spec standard — ideas, extensions, and directions that warrant eventual action but aren't ready to become proposals today. Each entry carries its rationale and an explicit trigger for revisit, so the idea survives turnover and nothing is lost waiting to be rediscovered.

Not a task list. Not a prioritised roadmap. When an entry's trigger fires, it graduates to a proposal under `proposals/`. Closed entries move to a `## Closed` section at the bottom with a pointer to the graduating artifact.

## Format

```
## <short title>

**Added:** YYYY-MM-DD by <author>
**Rationale:** why this warrants eventual action.
**Trigger:** the concrete condition(s) that should bring this back to active consideration. Dated or state-based, not "someday".
**Context:** relevant specs, discussions, prior work — enough that a future reader can pick it up without asking anyone.
**If adopted:** what graduation looks like (proposal? spec addition? existing-spec section?).
```

---

## Open

### Prototype interactive commands: read-only default, no command-directory wiring until graduation

**Added:** 2026-07-22 by Javier Fernandez

**Rationale.** Contract 1 Case A of the `agent` capability ([`specs/tooling/agent/spec.md`](./specs/tooling/agent/spec.md)) governs prototype *agents* — scheduled, unattended processes running with `--dangerously-skip-permissions` — with a project spec, a declared write scope, and a security contract. It says nothing about prototype *interactive commands*: human-invoked tools being validated before graduation. Two questions Contract 1 doesn't answer for this case: (1) should a prototype command be wired into the adopter's command directory (`.claude/commands/` or equivalent) the way a graduated capability's command is, or does that risk contributors discovering and depending on unvalidated behaviour before the close criterion is met? (2) what write scope should a prototype command default to — Contract 2's write-scope-validator pattern assumes some declared write scope, but a prototype whose only purpose is to answer questions about existing content (a query/read tool) arguably needs none at all, and the default should be explicit read-only rather than relying on an adopter to remember to narrow it.

**Trigger (OR'd — first fires).**
- A second prototype interactive command is built and the same two questions recur, making it worth a shared answer instead of an ad hoc one per prototype.
- A prototype command gets wired into a command directory during validation and a contributor starts depending on it before it graduates, causing real disruption when its behaviour changes or it's abandoned.
- The `catalogue-edges` prototype (validating a relationship-graph query against `catalogue`) reaches its close criterion and the promotion has to decide, for the first time, how the prototype-command phase should have been governed.

**Context.**
- Surfaced 2026-07-22 while scoping a prototype project to validate a graph-relationship query command (extending `catalogue` with typed edges derived from `## Related`/`## Dependencies` sections). The prototype is deliberately read-only and deliberately not wired to a command directory during validation, but nothing in `tooling/agent/spec.md` states that as a rule — it was an ad hoc judgment call for this instance.
- Contract 1 Case A already distinguishes prototype vs. graduated agents for scheduled/unattended tools; this entry is about the parallel distinction for interactive, human-invoked tools, which Contract 1's fields (write scope declaration, security layers) weren't written with in mind.

**If adopted.** Graduates as a short addition to Contract 1 (or a new Contract 1b) in `specs/tooling/agent/spec.md`, or a section in `specs/tooling/spec.md` if it turns out to be a `tooling`-capability-wide concern rather than specific to `agent`: a prototype interactive command defaults to no declared write scope (read-only) unless the project spec explicitly declares one, and is invoked directly (ad hoc prompt or a script under the project folder) rather than wired into the adopter's command directory until it graduates.

---

### B-004: Risk registry daily delta implementation

**Added:** 2026-06-06 by Javier Fernandez

**Rationale.** The risk registry (`governance/catalogue/risks.yaml` or equivalent) is regenerated today as a full rebuild. With the [catalogue capability](./specs/tooling/catalogue/spec.md) now emitting a split index plus per-type sub-files, and the [tooling delta-mode pattern](./specs/tooling/spec.md#delta-mode) now defined, the risk registry is a natural candidate for a daily delta implementation: read the fresh catalogue, compute `git log --since="<last_run>" --name-only` over the `risks/` paths, and update only changed risk entries rather than rebuilding the whole registry each run. This cuts the daily cost of keeping the registry current and proves the delta-mode pattern on a second consumer beyond conformance.

**Trigger (OR'd — first fires).**
- The risk registry rebuild becomes a measurable cost in the agent-metrics weekly report (high `avg_files_read`, `catalogue_assisted: false`).
- A second registry-style derived artefact wants the same daily-delta treatment, making a shared implementation worthwhile.
- `risk-at-scope` is revised for any other reason and the delta implementation is the natural co-revision.

**Context.**
- Depends on the delta-mode pattern in [`specs/tooling/spec.md`](./specs/tooling/spec.md#delta-mode) and the split catalogue format in [`specs/tooling/catalogue/spec.md`](./specs/tooling/catalogue/spec.md).
- The risk record schema and RAG derivation live in [`specs/risk-at-scope/spec.md`](./specs/risk-at-scope/spec.md); the registry projection is consumed by [`specs/observability/stakeholder-report/spec.md`](./specs/observability/stakeholder-report/spec.md) (Risk health section).

**If adopted.** Graduates as a delta-mode implementation note on the risk registry generation (either a section in `risk-at-scope` or a dedicated registry-generation agent spec under tooling), referencing the shared delta-mode pattern rather than restating it.

---

### B-005: Governance monitor daily workflow (inbox-health + decision-health)

**Added:** 2026-06-06 by Javier Fernandez

**Rationale.** Two observability tools — [`inbox-health`](./specs/observability/inbox-health/spec.md) and [`decision-health`](./specs/observability/decision-health/spec.md) — together answer the daily governance-monitor question: *are asks being answered, and are decisions being made?* Running them as a coordinated daily workflow (rather than relying on ad-hoc invocation) would give a standing governance-health surface that refreshes every day, complementing the on-demand pull model. This pairs with the [`decision-escalation`](./specs/governance-at-scope/tools/decision-escalation/spec.md) tool, which acts on the stale decisions `decision-health` surfaces.

**Trigger (OR'd — first fires).**
- An adopter wants a single daily governance-health refresh rather than invoking the two tools separately.
- The observability suite (`suite.md`) is revised and a governance-monitor sub-grouping becomes the natural shape.
- `decision-escalation` activation creates demand for a daily `decision-health` feed to drive it.

**Context.**
- The observability suite at [`specs/observability/suite.md`](./specs/observability/suite.md) already runs all five tools sequentially; this entry is about a tighter, governance-focused daily sub-workflow (inbox-health + decision-health) rather than the full five-tool suite.
- `decision-escalation` routes disposition requests for stale decisions; `decision-health` surfaces them. The two are complementary — one measures, one acts.

**If adopted.** Graduates as a named workflow variant in `specs/observability/suite.md` (a governance-monitor sub-suite) or a standalone scheduled-workflow note, wiring `inbox-health` and `decision-health` on a daily cadence.

---

### B-001: Agent-creation command

**Status:** Open (still). A command that scaffolds a new automated agent (project spec or Case-B capability declaration, write-scope declaration, security layers, implementation wiring, and invocation-log instrumentation) from the [`agent` four-contract spec](./specs/tooling/agent/spec.md). Not yet started. Tracked here so it is not lost amid the v0.2.0 restructuring; the agent contract spec it would scaffold against is stable and unchanged by this release.

---

### Git-level protection mechanisms for direct-push adopters

**Added:** 2026-05-22 by Javier Fernandez

**Rationale.** The `adoption-manifest` capability defines three protection layers for the manifest (spec-level, Git-level, agent-level). The Git-level layer as currently described — CODEOWNERS or branch-protection rules — assumes a PR-based workflow. Adopters using direct-to-main pushes (a direct-to-main collaboration default that is a legitimate contribution model) cannot use CODEOWNERS because it only fires on PRs. The standard currently offers no Git-level mechanism for these adopters; protection falls entirely to the agent-level layer. Two candidate mechanisms exist but neither is specified: **GitHub Push Rulesets** (path-based push restrictions enforced at the remote, requires GitHub admin to configure) and **server-side notification hooks** (a GitHub Action or webhook that posts to a chat channel when protected paths change — doesn't prevent, but surfaces unauthorised edits within seconds).

Without a standard-level answer, every direct-push adopter either re-invents the protection or accepts that Git-level is unavailable. Neither outcome is good for adopters who want defence-in-depth.

**Trigger (OR'd — first fires).**

- An adopter using direct-push reports an incident where an unauthorised edit landed on a protected path before agent-level caught it.
- A second adopter independently invents one of the candidate mechanisms (push rulesets, notification hook, or a third option) and asks the standard to canonise it.
- The direct-to-main collaboration model is articulated as a contribution-model section in the standard, and Git-level protection becomes a natural co-revision.
- A reference-implementation adopter chooses to implement one of the mechanisms, validates the shape, and proposes it back.

**Context.**

- Surfaced 2026-05-22 while adopting the `adoption-manifest` capability in a reference implementation that uses direct-to-main. CODEOWNERS does not apply; the spec was updated to clarify that agent-level becomes primary in this workflow, but the Git-level gap remains.
- Candidate mechanisms:
  - **GitHub Push Rulesets** — newer GitHub feature (2024+) allowing org or repo admins to restrict pushes by path, branch, or user. Could block pushes that touch `.open-org-spec/` from non-owner accounts. Requires GitHub admin configuration; not all adopters have admin access.
  - **Server-side notification hook** — a GitHub Action (or equivalent CI step) that triggers on pushes to protected paths and posts to a chat channel. Doesn't prevent edits but surfaces them immediately for review/revert. Lower setup cost; no admin access required beyond write to `.github/workflows/`.
  - **Hybrid** — notification as the default (low setup), with push rulesets as an escalation for adopters with admin access.
- The agent-level rule template (added to `adoption-manifest/spec.md` on 2026-05-22) is the immediate primary protection for direct-push adopters; this entry covers the Git-level complement, not a replacement.

**If adopted.** Graduates as a section addition to `adoption-manifest/spec.md` (the "Manifest ownership and protection" section), naming the candidate mechanisms and the per-adopter trade-offs. May also produce a small companion guide showing the GitHub Action template for the notification hook. If the mechanisms generalise beyond manifest protection (e.g., applicable to any owned spec or governance folder), the section could lift to its own capability under `specs/protection/` or similar.

---

### Graduate ingest, onboard, and scan-channels to the tooling capability

**Added:** 2026-05-22 by Javier Fernandez

**Rationale.** Three tools in the reference implementation share the same governed category and role-detection primitive as `catchup`, which graduated on 2026-05-22. Each validates a distinct pattern: `ingest` routes content from an inbox into the right place in the repo; `onboard` orients a first-time contributor and proposes their `people.md` row; `scan-channels` pulls activity from live communication channels and surfaces candidates for ingestion. All three are multi-consumer tools that belong at infrastructure scope per the tooling capability's ownership rule.

**Trigger (OR'd — first fires).**

- Any of the three tools reaches its v0 close criterion in the reference implementation.
- A second adopter independently builds an equivalent tool and asks the standard for a canonical shape.
- The shared role-detection primitive used by all four tools (catchup + these three) is extracted as a named shared layer — that extraction is the natural moment to graduate the tools that depend on it.

**Context.**

- Live instances in a reference implementation: an ingest tool, an onboard tool, and a scan-channels tool, each scaffolded as its own v0 project. All three are active; none has met its v0 close criterion yet.
- All three reuse the same role-detection logic as `catchup` (Owner/Lead/Driver/Approver headers). That shared primitive has no canonical home; extracting it is a prerequisite for a clean graduation.
- `ingest` and `onboard` both interact with the feedback-inbox capability (graduated 2026-05-22): `ingest` routes content that may include feedback entries; `onboard` opens a `people.md` proposal via a feedback entry.
- `scan-channels` depends on the adopter's live-channel configuration (Teams, Slack, or equivalent) — the generic spec will need an extension-point model for channel integrations.

**If adopted.** Graduates as three additions to `specs/tooling/`: `ingest/spec.md`, `onboard/spec.md`, `scan-channels/spec.md`. Each follows the shape established by `catchup/spec.md`. The shared role-detection primitive either graduates alongside them as a shared skill spec (`specs/tooling/role-detection/spec.md`) or is documented as a section within each tool spec. The three v0 projects close with pointers to the new specs.

---

### Extract decision-making as a first-class capability, parallel to `people`

**Added:** 2026-05-22 by Javier Fernandez

**Rationale.** `governance-at-scope` currently does double duty: it defines the structural meta-layer (where governance lives, folder conventions, scope hierarchy, precedence, contradiction detection) *and* owns the DACI schema (Driver / Approver / Contributors / Informed, frontmatter shape, role definitions). With `people` now extracted as a sibling capability covering standing membership, the asymmetry is visible — DACI is the same kind of block as `people`, but it has not been separated out. The result is that `governance-at-scope` is simultaneously the container and one of the things it contains.

The cleaner model is three distinct layers:

- **`governance-at-scope`** — the structural meta-layer: folder conventions, scope hierarchy, precedence, contradiction detection. The container.
- **`people`** — a block: standing membership, lead accountability. Answers "who is here?"
- **`decision-making`** — a block: DACI, per-scope decision authority. Answers "who decides here?"

Both blocks compose into a governed scope. A scope can adopt the container without either block, or either block without the other. Neither block duplicates the other.

**Trigger (OR'd — first fires).**

- A second adopter independently models decision authority and produces a shape that diverges from the DACI frontmatter buried in `governance-at-scope`, making the implicit standard ambiguous.
- A tool is proposed that queries DACI across scopes and needs a canonical capability spec to target, not a section inside `governance-at-scope`.
- The `governance-at-scope` capability is revised for any other reason and the extraction is the natural co-revision.
- The `people` capability (graduated 2026-05-22) accumulates a second adopter instance, confirming the block model is sound and making the asymmetry with decision-making harder to justify.

**Context.**

- Surfaced on 2026-05-22 while drafting `specs/people/spec.md`. The `people` extraction made the parallel structure visible: DACI is the same kind of modular block as `people`, but remains embedded in `governance-at-scope`.
- Current DACI content in `governance-at-scope/spec.md`: the YAML frontmatter schema (scope, applies_to, owner, daci, cross_references), the Driver / Approver / Contributors / Informed role definitions, the Owner-as-default-DACI convention, and the TBD fallback rule. These are the contents that would migrate to a new `decision-making` capability.
- What stays in `governance-at-scope` after extraction: the folder-convention rule (`governance/` at each scope), the `decisions/` sibling convention, the minimum-required-declarations rule, scope-discipline rule, precedence rule, contradiction-detection rule. These are structural — they describe the container, not its contents.
- The cross-reference added to `governance-at-scope/spec.md` Related on 2026-05-22 (pointing at `people/spec.md`) would need a sibling cross-reference to `decision-making/spec.md` once it exists.
- **Live instance to study:** a reference-implementation cluster decision on quarterly priority workflows. This decision uses `**Decider(s):**` (a flat named list) rather than full DACI (Driver / Approver / Contributors / Informed). It also follows a full ADR shape — Context, Decision, Rationale, Consequences, Alternatives Considered, Related — which is not defined anywhere in the standard. Two gaps this surfaces for a `decision-making` capability: (1) the relationship between `Decider(s)` and DACI is unspecified — are they the same thing, or is `Decider(s)` a lightweight variant for operational decisions that don't warrant full governance DACI? (2) the ADR format (what sections a decision record must carry, what is optional) is not standardised — that cluster decision uses a rich shape that has proven useful in practice but is not canonical. A `decision-making` capability would need to address both: define the lightweight vs full DACI distinction, and codify the ADR section schema.

**If adopted.** Graduates as a new `specs/decision-making/spec.md` capability, with:

- The DACI schema and role vocabulary migrated verbatim from `governance-at-scope`.
- A slim `governance-at-scope` that sheds the DACI content and gains a Related pointer to `decision-making`.
- Cross-references updated in `people/spec.md` (its lead-table/governance note references `governance-at-scope` by name; after extraction the reference would shift to `decision-making`).
- An `oos:adopt-decision-making` command parallel to `oos:adopt-governance`, or an extension of the existing adopt command to cover both blocks in one flow.

### [Graduated] Command protocol for `oos:` commands

**Added:** 2026-04-24 by Javier Fernandez
**Graduated:** 2026-05-22 → distributed across multiple specs (no single home; conventions operational across six commands)

**How it graduated.** Rather than a single proposal, the four sub-elements named in the original "If adopted" outcome landed across separate specs as commands accumulated through the `adoption-manifest` and `tooling` work on 2026-05-22:

- **Command-definition location convention** → standard tools at `specs/tooling/<tool>/spec.md`; capability commands at `specs/<capability>/<verb>.md`. Stated in [`specs/tooling/spec.md`](./specs/tooling/spec.md) and [`specs/adoption-manifest/spec.md`](./specs/adoption-manifest/spec.md).
- **Common command-definition shape** → six commands now follow Purpose / Preconditions / Inputs / Outputs / Steps / Refusal conditions / Non-goals: [`adoption-manifest/adopt.md`](./specs/adoption-manifest/adopt.md), [`adoption-manifest/extend.md`](./specs/adoption-manifest/extend.md), [`tooling/adhere-to/spec.md`](./specs/tooling/adhere-to/spec.md), [`project/new.md`](./specs/project/new.md), [`governance-at-scope/adopt.md`](./specs/governance-at-scope/adopt.md), and [`tooling/catchup/spec.md`](./specs/tooling/catchup/spec.md). The shape is in-use convention, not separately documented.
- **Invocation-resolution rules** → relay pattern in [`specs/tooling/spec.md`](./specs/tooling/spec.md) ("Canonical spec location for scoped commands") and the standard-command relay shape declared by each adopter's tooling extension.
- **Command-catalogue mechanism** → the adopter's commands README under "Standard commands (from active capabilities)", wired by [`adhere-to`](./specs/tooling/adhere-to/spec.md) step 4 on capability activation. Source of truth is the manifest's `capabilities` + `tool_extensions` map.

**Open follow-up.** The conventions work but are not consolidated in a single spec. A future `command-protocol` capability could extract the cross-cutting rules from the four specs above without changing behaviour. Trigger for that consolidation: a third-party LLM interface (Cursor, GPT, other) attempts to operate on a conformant repository and cannot find command definitions because the conventions are scattered. Not a current need.

**Original rationale (preserved for context).** The standard includes `oos:`-prefixed commands that adopters invoke via their LLM interface (e.g., `oos:adopt-governance`). The first command was drafted alongside the governance-at-scope capability and co-located with it at `specs/governance-at-scope/adopt.md`. No general protocol yet defines: (a) where command definitions live across capabilities — per-capability co-location, top-level `commands/` folder, or both; (b) how an LLM resolves a command invocation (e.g., `oos:adopt-governance`) to its definition file; (c) what shape command definitions take at the capability-agnostic level (common frontmatter schema? required sections?); (d) how commands are catalogued and discovered by LLMs unfamiliar with a specific conformant repo. Running a single command produced a concrete draft; generalising requires a second command to compare against.

### Migration mode for `oos:adopt-*` commands

**Added:** 2026-04-24 by Javier Fernandez

**Rationale.** The `oos:adopt-governance` command (see `specs/governance-at-scope/adopt.md`) is designed for greenfield adoption: the scope being governed must have no existing governance folder. In practice, the more common case for an organisation adopting the standard is **migration** — they already have governance content (in some shape or another), and adopting the standard means bringing that content to conformance with the schema, not replacing it. Running the adopt command against a repository with existing non-conformant governance surfaced the gap: the command refuses (per its refusal-condition rule), but the real need is to convert what exists — preserve prose, add frontmatter, restructure folder layout (e.g., move nested `governance/decisions/` to peer `decisions/`). A migration flow is a separate shape from greenfield adoption.

**Trigger (OR'd — first fires).**
- A second `oos:adopt-*` command is designed and the same gap appears for its capability.
- An adopter reports trying to apply the standard to an existing repository and hitting the refusal.
- A reference implementation completes its ad-hoc migration and the lessons from that migration are ready to be codified.

**Context.**
- Surfaced while running `oos:adopt-governance` against a reference implementation, which already had a `governance/` folder with prose-only content and a nested `decisions/` subfolder. The command refused on conflict; the adoption proceeded informally under a "migration mode" that isn't specified anywhere.
- That reference implementation's actual migration is documented in its commit history from 2026-04-24 (the date the adoption simulation was run).

**If adopted.** Graduates as either a new `oos:migrate-governance` command (parallel to `adopt.md`) or a migration mode on `adopt.md` itself. The flow needs to: read existing governance content, detect its shape against the schema, identify the delta, apply changes that preserve prose and move structure, surface cross-reference updates the adopter has to make in other files.

### Adopter-state detection protocol for commands

**Added:** 2026-04-24 by Javier Fernandez

**Rationale.** Commands that modify a conformant repository (e.g., `oos:adopt-governance`) need to inspect existing state before acting — whether governance already exists at the target scope, whether conflicting structure is present, whether the target scope itself exists, what higher-scope governance already applies. Currently each LLM executing a command would improvise its own detection. A defined protocol would keep behaviour consistent across LLM interfaces, and would serve as a shared primitive for other capabilities that need to read repo state (contradiction detection across scopes, for example).

**Trigger (OR'd — first fires).**
- A second command is designed that needs to detect repo state, and the detection logic starts duplicating across commands.
- An adopter reports unexpected behaviour because their LLM missed pre-existing state.
- Contradiction detection (a separate capability outlined in `specs/governance-at-scope/spec.md`) requires the same state-inspection primitives and starts to duplicate logic.

**Context.**
- Surfaced while running `oos:adopt-governance`: the command could not inspect the adopter's repository to know what governance was already present, so the simulation proceeded under a greenfield assumption.
- Related to contradiction detection (flagging rules that contradict higher-scope rules) and to the catalogue proposal below — both would benefit from a defined state-inspection primitive.
- **First concrete instance (2026-05-22):** the [`adhere-to`](./specs/tooling/adhere-to/spec.md) tool exercises one model of repo-state inspection — walk affected paths declared by the capability, infer ownership from role headers in `<scope>/people.md` or spec-level `Owner:` fields, detect gaps against the capability's rules, fall back to manifest-owner inbox when no scope owner can be inferred. The trigger *"A second command is designed that needs to detect repo state"* has fired with `adhere-to`. The protocol is not yet extracted as standalone; the pattern is observable in `adhere-to/spec.md` steps 1–3 and can serve as the seed when a second instance accumulates.

**If adopted.** Graduates as a shared capability or sub-capability under command protocol: defines which paths LLMs read, what structure they return, how missing-or-ambiguous state is surfaced, and fallback behaviour.

### Two-layer representation: LLM-maintained structured catalogue alongside canonical markdown

**Added:** 2026-04-24 by Javier Fernandez

**Rationale.** A repository conforming to this standard uses a single representation — human-readable markdown — for three simultaneous purposes: humans reading, humans authoring (LLM-mediated), and machines (LLMs and derived tools) querying. These three roles have different optimal shapes; prose is verbose and unstructured, while machine queries benefit from compact structured data. At small scale, a single representation serves all three adequately. At larger scale — once enough tools exist that query the same ownership/routing data, or once the repo crosses a size where per-tool prose-walking becomes a material latency and token-cost burden — the compromise shows.

The proposed shape: canonical markdown stays unchanged for humans. A **structured catalogue** (a single repo-level YAML file, or distributed sidecar files per artifact) holds the machine-readable projection of governance state — who owns what, stakeholder/addressee relationships, parent-thesis links, status summaries. LLMs maintain it automatically on every canonical write. Because authoring in a conformant repo is already LLM-mediated, keeping two representations in sync is the LLM's job, invisible to contributors. Tools query the catalogue cheaply; prose reads happen only when a tool genuinely needs intent context for a specific artifact.

**Expected benefit.** Roughly 3–5× token-per-query reduction at early adopter scale; the gap widens non-linearly with repo growth. Later tools (inbox aggregators, ownership lookup, new-contributor orientation) inherit the cheap query layer rather than each re-solving the prose-walking cost problem. At scale, the catalogue moves from optimisation to necessity — tool-based onboarding is how a conformant repo teaches itself to new contributors, and it has to be cheap enough and fast enough to hold.

**Trigger (OR'd — first to fire wins).**

- A reference implementation reports tool latency or token cost as a contributor complaint.
- A second tool is proposed against the standard that would benefit from structured ownership / addressee data.
- A reference implementation's repo exceeds a scale where linear prose-walking in tools becomes visible in cost or latency reports.
- Periodic revisit: 6 months after this entry's added date.

**Context.**

- Surfaced during adoption work in an early reference implementation. Specifically: a role-play of a returning contributor against the first tool built on the standard exposed two addressee-detection gaps. (1) The tool only handled per-entry `→ <name>` addressee markers inside feedback files, missing file-level addressing used by modules with a single named Owner. (2) Both conventions are legitimate — file-level addressing is natural when a module has a single Owner; per-entry addressing is the natural pattern when it doesn't. Any tool querying against the standard must handle both.
- The tactical fix in that implementation — folder-ownership detection that reuses data the tool already computes — solves the immediate bug cheaply. The strategic direction captured here is that similar-shape problems will recur in every future tool unless structured data is lifted into its own layer.
- Economics considered: catalogue maintenance shifts cost from pull-time (every tool query) to push-time (LLM write). At any non-trivial query-to-write ratio — which a conformant repo with multiple tools and multiple contributors per tool will reach — the shift is a net saving. Break-even is roughly ~8–15 pulls per write; observed ratios at adopter scale exceed that comfortably.

**If adopted.** Graduates as a proposal against the standard with:

- Catalogue schema covering ownership/roles, feedback addressees, parent-thesis links, status summaries, stakeholder relationships.
- LLM authoring discipline: a standard-level rule that on every canonical write, the LLM updates the catalogue projection.
- Validator: regenerate catalogue from canonical; diff against committed version; fail the check if drifted. The catalogue is a projection, not a source — recoverable by regeneration from the canonical markdown.
- Migration pattern for existing conformant repos: retroactive catalogue entries, in batch or lazy on next edit.
- Reference-implementation tool rewrites to query catalogue-first, fall back to prose walk as a safety net.

### Cross-capability edits in capability-lifecycle

**Added:** 2026-04-24 by Javier Fernandez

**Rationale.** `capability-lifecycle` at v0 maps `specs-delta/<path>` to `specs/<change-slug>/<path>`. This covers changes that *add* a new capability (the slug doubles as the target capability name) and changes that *fully replace* one capability when slug match is acceptable. It does not cover changes that *modify an existing capability whose name differs from the slug* — e.g., a change slugged `archive-at-root` that edits `capability-lifecycle`'s spec. The first such case (relocating the graduated-proposals archive folder to sit as a sibling of the changes folder) was handled as a direct edit outside the workflow, matching the lifecycle spec's own v0 caveat.

**Trigger (OR'd — first fires).**

- A second cross-capability edit is needed, and handling it outside the lifecycle a second time risks normalising the skip.
- A contributor opens a change that would modify two different existing capabilities in one change and asks how to structure it.
- A third-party adopter contributing upstream hits the gap while trying to modify an existing capability whose name differs from their change slug.

**Context.**

- Surfaced 2026-04-24 while relocating the graduated-proposals archive folder to sit as a sibling of the changes folder. The change modified `specs/capability-lifecycle/spec.md` under a slug (`archive-at-root`) that does not match the target capability. The lifecycle spec itself flagged this shape as a v0 limitation and deferred resolution.
- The GUIDE.md opt-in edit (2026-04-24) is a different class — it edits a meta-doc, not a capability spec — but shares the "direct edit, outside the workflow" pattern. Worth considering whether the two should be covered by one resolution or two.

**If adopted.** Graduates as a proposal that adds either a `target: <capability>` field to the proposal frontmatter schema or a `specs-delta/<capability>/` subfolder convention for cross-capability edits. Either option is a small schema extension; it also defines how migrations retroactively cover content that was direct-edited during bootstrap.

### [Graduated] Feedback-inbox as a per-scope capability

**Added:** 2026-04-30 by Javier Fernandez
**Graduated:** 2026-05-22 → [`specs/feedback-inbox/spec.md`](./specs/feedback-inbox/spec.md)

**Rationale.** A reference implementation now uses a `feedback.md` file at multiple scopes — a cross-cluster inbox, a cross-cutting infrastructure inbox, and per-project inboxes for several active projects. The pattern has stabilised into a recognisable shape: a file-level inbox for cross-contributor observations addressed to a specific owner or owners, with two entry formats (one-liner and `## YYYY-MM-DD | <author> — <title>` headings), an `[resolved]` heading prefix on close, and inline responses from the addressee. A live tool — the reference implementation's `catchup` command — depends on the `→ <name>` addressee convention to surface inbox items in a returning contributor's digest. Without a standard-level spec, every adopter (and every tool built against the standard) re-derives the format and the addressee-detection rules.

Two distinct addressing modes appear in the wild and both are legitimate. **File-level addressing**, where a module has a single named Owner and every entry implicitly addresses them (an infrastructure-module inbox addressed to its single owner; a closed tool project's inbox addressed to its owner). **Per-entry addressing**, where the file serves multiple recipients and entries carry an explicit `→ <name>` arrow (a cross-cluster inbox addressed to specific cross-cluster operators). A standard-level spec must accommodate both without forcing adopters to choose at adoption time.

**Trigger (OR'd — first fires).**

- A third tool is proposed against the standard that needs to query feedback inboxes (after `/catchup`, the second is likely a stakeholder-onboarding orientation tool).
- An adopter outside the reference implementation reports inconsistency or ambiguity in the inbox shape.
- The `two-layer representation` backlog entry graduates and the catalogue schema needs a feedback-inbox projection — defining the projection without a canonical spec to project from is awkward.
- Resolution flow ambiguity surfaces as a real bug: an entry is marked `[resolved]` without a pointer to the actioning artifact, or an entry's response chain becomes unreadable across multiple back-and-forths.

**Context.**

- Live instances in a reference implementation: a cross-cluster feedback inbox, a cross-cutting infrastructure inbox, and several per-project inboxes.
- The reference implementation's `catchup` command relay currently scans changed feedback files for `→ <name>` headings to populate a returning contributor's inbox section; it does not yet handle file-level addressing as a first-class case.
- Convention for substantive entries (heading form): `## [resolved]? YYYY-MM-DD | <author>[ → <addressee>] — <short title>`, body sections **Observation / Why this matters / Suggested direction (not a decision) / If you disagree**.
- Convention for short entries: `- YYYY-MM-DD | <author>[ → <addressee>] | <one-liner>`.
- Resolution: prefix heading with `[resolved]` and add a pointer line (in one reference-implementation inbox, this lands as a `**Resolved YYYY-MM-DD.**` paragraph at the bottom of the resolved entry, with commit SHAs or spec links as the actioning pointer).

**If adopted.** Graduates as a proposal for a new `feedback-inbox` capability under `specs/`, with: a file-location convention covering scope ranges (`<scope>/feedback.md`); the heading and one-liner formats with addressee variants; the addressee-detection rules covering both file-level and per-entry modes; the resolution flow with pointer requirements; the relationship to tooling (the standard names the addressee-detection rules tools must implement). Likely co-graduates with the `oos:` command-protocol entry above to define a `oos:feedback` style invocation if useful.

### Updates-ledger as a projection of project work, not a manual file

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** Every active project in the reference implementation now carries an `updates.md` and stakeholders rely on it as their progress read surface. The pattern has hardened, but the *mechanism* it currently uses is wrong: contributors hand-edit the file. That makes the ledger a duplicate source of truth — it drifts from the actual work (commits, decisions, feedback resolutions, status changes), it costs contributor time to maintain, and a stakeholder reading a stale `updates.md` learns the wrong thing.

The right shape is a **projection** of the project's existing artifacts: git history scoped to the project's folder, entries in `decisions/`, resolved feedback entries, status transitions in `spec.md` frontmatter. The ledger gets generated, not written. Manual content shrinks to the curatorial layer that *cannot* be derived — primarily forward-looking intent ("Next") and risk callouts that live in the project owner's head, not in committed work.

This is a sibling shape to the **two-layer representation** backlog entry above: both move from canonical-markdown-as-everyone's-source to canonical-markdown-plus-projections. The updates-ledger is one projection; the structured catalogue is another. Co-graduating them would let the same projection discipline cover both.

**Trigger (OR'd — first fires).**

- A contributor reports their `updates.md` is stale because keeping it current competes with shipping the work it tracks.
- A stakeholder reading `updates.md` learns something contradicted by the actual repo state (commits, decisions, status), exposing the dual-source problem.
- The two-layer representation entry above graduates; the projection discipline can be reused for the ledger as a second projection.
- A tool is proposed that aggregates progress across projects (top-3 view, weekly digest, stakeholder-specific roll-up) and would benefit from querying derived data rather than walking each project's hand-written `updates.md`.

**Context.**

- Live instances in a reference implementation (manually maintained, drift risk live): several active projects each carry an `updates.md`. Variant: one project uses a `tasks.md` (tasks rather than updates).
- The reference implementation's weekly-update process describes a top-3 weekly update assembled from per-project `updates.md` content. If `updates.md` becomes a projection, the weekly update is a projection-of-projections — built from the same source data.
- Projection sources: git commits scoped to a project's folder (and any cross-cutting paths the project touches by reference); entries under the project's `decisions/`; resolved entries in the project's `feedback.md`; status transitions in the project's `spec.md` frontmatter.
- Curatorial layer (still authored, not derived): forward-looking "Next" intent and "Callouts" (risks / metric changes / things-to-flag) that aren't in committed work yet. Lives somewhere — possibly in a new section of `spec.md` itself, possibly in a small adjacent file. The projection assembles around it.

**If adopted.** Graduates as a proposal that defines:

- The projection sources (git history, `decisions/`, feedback resolutions, status transitions) and how each maps to ledger entries.
- The curatorial layer (where "Next" and "Callouts" live; who maintains them).
- The regeneration mechanism — a command (`oos:project-updates` style under the command-protocol entry above) plus a validator that flags drift between projection and committed `updates.md` if the file is checked in at all.
- An open question: whether `updates.md` is checked into the repo (regenerated on demand, validated against drift) or generated on-the-fly without persistence (cheaper to keep current, harder to link to from other specs). Either choice has live trade-offs that should be evaluated during graduation.
- The relationship to the two-layer representation entry: shared projection discipline.

### Parent-thesis relationship in the project schema

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** A reference implementation has begun running multiple time-boxed projects under a single longer-arc thesis: a parent thesis project (accepted 2026-04-23) with two sibling projects testing different angles of it. Each sibling project carries a `Parent thesis:` field in its prose body pointing back at the parent. The relationship is real but not in the `project` capability's frontmatter schema — meaning a tool reading project state has to walk prose to discover it.

The pattern is structural, not adopter-specific: a long-running thesis spawns short experiments that test different facets. Without a schema field, the relationship is lossy across tools, and a new sibling has no canonical location to declare its parentage.

**Trigger (OR'd — first fires).**

- A third sibling project lands under the same parent thesis (likely soon — the current count is two; the broader thesis has more angles than two experiments cover).
- A second adopter independently invents a parent-thesis-style relationship and asks how to express it.
- A tool is proposed that needs to traverse parent → sibling relationships (e.g., a roadmap view that groups projects by thesis).
- The `project` capability is revised for any other reason; the missing field is the natural co-revision.

**Context.**

- Live instances in a reference implementation: the parent thesis project uses a `proposal.md` not a `spec.md` (a separate variant worth tracking); two sibling projects carry `**Parent thesis:**` fields pointing at it.
- The current `project` capability spec has no `parent` or `parent-thesis` field. Every parent-thesis link is in prose, requires a tool to grep, and doesn't enforce the back-pointer to verify the parent acknowledges the child.
- That reference implementation's parent thesis is itself shaped as a `proposal.md` not a `spec.md`, with a fuller frontmatter (DACI, Mandate, Decision authority, Policy compliance, Principles cited, Depends on). That richer shape is a separate question — possibly its own backlog entry — but interacts with this one because if the parent isn't a `spec.md`, the back-pointer convention has to handle the variant.

**If adopted.** Graduates as a small extension to `specs/project/spec.md`'s frontmatter schema: an optional `parent: { thesis: <slug-or-path> }` field, plus prose-section guidance on when a project has a parent (it tests / executes a hypothesis stated in the parent), and what the parent must declare in its own spec to legitimise the child relationship. Adopter-side guidance: existing prose `**Parent thesis:**` lines migrate to the frontmatter field on next edit.

### [Graduated] Project initiation gate + per-project adherence check

**Added:** 2026-05-27 by Javier Fernandez
**Graduated:** 2026-05-27 → multi-spec bundle landing on the same day. Project lifecycle: five-state model `started → proposed → in-progress → closed/cancelled` with [Gate A content gate](./specs/project/spec.md#gate-a--started--proposed-content-gate) and [Gate B approval gate](./specs/project/spec.md#gate-b--proposed--in-progress-approval-gate); [Cancellation](./specs/project/spec.md#cancellation) reachable from any pre-closed state. Adherence: [`#### Against project`](./specs/adherence-check/spec.md#against-project) checks updated for the new states. Tooling: [Step 2a fix-with-me](./specs/tooling/adhere-to/spec.md#step-2a--fix-with-me-flow-when-mode--fix-with-me) + [Target input](./specs/tooling/adhere-to/spec.md#inputs) + [stamping](./specs/tooling/adhere-to/spec.md#stamping) added to `adhere-to`. Adoption stamps: [Tooling stamps](./specs/project/spec.md#tooling-stamps) frontmatter convention; [Tool stamping principle](./specs/tooling/spec.md#tool-stamping-state-changing-tools) at the parent tooling capability. Adopter extension: `started` added to status vocab, an office-hours pre-scaffold triage convention declared.

**Rationale.** The `project` capability defines what a spec must contain, and `/new-project` elicits the fields at scaffold. But the proposed → in-progress transition is currently a free local edit — *"Transitions are manual edits to the frontmatter… The capability does not automate transitions or gate them."* A project can go Active with `Close criterion: TBD`, no `Success metrics`, and the implementor as Owner (in direct violation of the *Project initiation* section's requester-authors-the-spec rule), and no surface catches it. The spec defers approval gating to `governance-at-scope`, but that capability operates at scope (cluster, module) level, not per-project-instance — so the deferral terminates in an empty space for the per-project case. Contributors who notice gaps (one implementor explicitly self-flagged "What 'done' means" in Open Questions on a proof-of-concept project) have nowhere to convert "I noticed" into "I must resolve before flipping status." Two coupled pieces fix the gap: a transition rule, and a tool the contributor can run on their own folder to know whether the rule is met.

**Trigger (OR'd — first fires).**

- A second project follows the same pattern (implementor-as-owner + close-criterion TBD + no success metrics) and gets blocked downstream — i.e., the gap repeats.
- A contributor explicitly asks "how do I know my project spec is ready to flip Active?" — the question implies the lack of a self-service check.
- `adhere-to` / `adherence-check` is extended beyond `governance-at-scope` to cover other capabilities; `project` is the natural co-revision.
- The `project` capability is revised for any other reason (e.g., the parent-thesis entry above graduates); the transition gate is the natural co-revision.

**Context.**

- Live example exposing the gap in a reference implementation: a proof-of-concept project scaffolded 2026-05-08 by the implementor, not the requester — direct violation of the *Project initiation* rule. Initial spec stated `Close criterion: To define with the contributor — see Open questions.` Status set to `Active` immediately. Close criterion + platform-decision content + build state only backfilled 2026-05-27, three weeks later, after the project had reached the platform-approver step. Success metrics never recorded.
- The base spec [`specs/project/spec.md`](./specs/project/spec.md) already names the requester-as-owner rule (*Project initiation* section) and already requires Close criterion + makes Success metrics an explicit elicitation prompt in [`new.md`](./specs/project/new.md). The content is in place. What's missing is the **enforcement surface** — a check the contributor can self-run, and a status transition that depends on it.
- [`specs/adherence-check/spec.md`](./specs/adherence-check/spec.md) already defines a check shape (findings with rule + target + severity + auto-fix flag) but scopes its target to `governance-at-scope` only. Extending the target set to include `project` instances is the natural shape; the finding model already fits.
- The existing repo-wide `adhere-to` runtime tool scans against named capabilities at repo scope. A per-project variant (`oos:adhere-to project <slug>`) would let the project owner run the check on a single folder and walk through prompts to fix each gap before flipping status.
- Adjacent: the *Lean-by-default: a complexity-challenger for adopters* entry below points the other direction (challenge a spec that has too much) — this entry challenges a spec that has too little. Both are conformance tools with different defaults.

**If adopted.** Two coupled extensions land together:

1. **`specs/project/spec.md` gains a *Transition gate* section** defining what must be true for the proposed → in-progress flip: required fields populated (no `TBD`), Owner matches the named requester or carries explicit recorded consent if not, Hypothesis present when `Type: experiment`, Success metrics present *or* an explicit "Success metrics: not applicable — <one-sentence rationale>". The gate is a contributor-self-check, not a CI block (v0); enforcement is the requirement to run the check and resolve findings before edit.
2. **`specs/adherence-check/spec.md` extends its target set to include the `project` capability**, with a per-project invocation `oos:adhere-to project <slug>`. The check produces the same finding shape; new option: an interactive *fix-with-me* mode that walks each gap and prompts the contributor for the missing field, then writes it into the spec on confirmation.

Adopter-side, an adopter's project extension can layer its own gate inputs onto the same check: Type, Cluster(s), Target close. No additional adopter work beyond declaring the fields in the existing extension.

### Adopter backlog as a first-class concept

**Added:** 2026-05-28 by Javier Fernandez

**Rationale.** The standard's backlog at [`open-org-spec/backlog.md`](./backlog.md) tracks candidate capabilities and extensions awaiting graduation — universal patterns the standard hasn't captured yet. Adopters have a parallel need: their own queue of adopter-specific candidates (extensions they need, capabilities they exhibit that no other adopter shares yet). Without an adopter-level backlog, those candidates either clutter the standard backlog (where they don't belong since they're not yet universal) or stay in contributors' heads. A reference implementation has just introduced an adopter backlog at its manifest folder (paired to its adoption manifest); the pattern is generalisable — any adopter would benefit from the same shape, with the same promotion path back to the standard.

**Trigger (OR'd — first fires).**

- A second adopter independently invents an adopter-backlog convention.
- A pattern in a reference implementation's adopter backlog actually promotes to the standard backlog (the promotion path validates the concept).
- A contributor outside the reference implementation asks where adopter-specific candidates should live.
- The `adoption-manifest` capability is revised for any other reason; the adopter-backlog concept is a natural co-revision.

**Context.**

- A reference implementation's adopter backlog at its manifest folder is the first instance — added 2026-05-28 alongside a framework-walkthrough onboarding deck. The deck walks the audience through the routing decision (adopter vs standard backlog) using a worked example.
- Same format as the standard backlog plus two adopter-specific fields: `Kind:` (candidate extension vs candidate adopter-only capability) and `Affects:` (which capability or extension the entry touches).
- The promotion path is the bridge: when a second adopter exhibits a pattern in another adopter's backlog, the entry lifts to the standard backlog. The adopter-side entry closes with `[Promoted YYYY-MM-DD]` and a pointer.
- Closely related backlog entry: *Migration mode for `oos:adopt-*` commands* (2026-04-24) — also a candidate enhancement to `adoption-manifest`. Could co-graduate.

**If adopted.** Graduates as a section addition to [`specs/adoption-manifest/spec.md`](./specs/adoption-manifest/spec.md) defining the adopter-backlog convention: file location (`.open-org-spec/backlog.md`), entry format, two-kind classification (`candidate extension` vs `candidate adopter-only capability`), promotion path with the `[Promoted]` close convention. The first adopter instance becomes the reference implementation. Other adopters get the convention for free; the standard backlog stays focused on universal patterns.

### Decision routing across scopes

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** A reference implementation's recent activity has produced decisions at multiple scopes that span others: several ADRs at cross-cutting infrastructure scope shape projects under that scope; a cluster-scope ADR pairs with a cross-cluster project. The `governance-at-scope` capability defines how governance is owned at each scope, but doesn't prescribe how a decision *routes* — i.e., when a decision belongs at the project, the cluster, the cross-cutting infrastructure scope, or the repo root.

A working heuristic the reference implementation appears to use: a decision lands at the highest scope at which its consequences need to be authoritative. A decision affecting one project lands in that project's `decisions/`; a decision affecting how a multi-project initiative is structured lands at the infrastructure scope's `decisions/` because it shapes multiple projects under that scope's mandate; a decision setting cluster-wide priority lands in the cluster's `decisions/`. The heuristic is implicit. Spec'ing it would name the rule a contributor uses without having to ask.

**Trigger (OR'd — first fires).**

- A contributor opens a decision at the wrong scope (one that should have been higher to bind the right audience, or one that should have been lower because it doesn't generalise) and the misplacement causes downstream confusion.
- A third decision is opened that's ambiguous about scope, and the recurrence is no longer a one-off.
- An adopter outside the reference implementation asks where a specific decision should live.
- The `governance-at-scope` capability is revised for any other reason and the routing rule is the natural co-revision.

**Context.**

- Recent multi-scope decisions in a reference implementation: the infrastructure scope's `decisions/` carries ADRs that affect projects; a cluster's `decisions/` carries a quarterly priority decision that pairs with a cross-cluster project; a cluster-group-scope role spec constrains what cross-cluster operators do — itself a governance artifact at a scope that doesn't fit "single cluster" or the infrastructure scope cleanly.
- A repo-root `decisions/` folder exists for repo-wide decisions. Per a reference implementation's contributor-instructions routing: "Repo-wide governance decisions (operating model, routing, ownership) → `decisions/YYYY-MM-DD-short-title.md` (peer to `governance/` per the scope-hierarchical pattern; inherits DACI from `governance/`)."
- The implicit heuristic — highest scope at which consequences need to be authoritative — has not been challenged yet, but it has not been articulated in either the standard or the adopter's contributor instructions.

**If adopted.** Graduates as a section addition to `specs/governance-at-scope/spec.md` defining: the routing rule (decision lands at highest scope where its consequences must be authoritative); per-scope `decisions/` folder convention (already implicit); cross-references between decisions at different scopes (a project decision that depends on an infrastructure-scope decision should reference it; an infrastructure-scope decision that supersedes project decisions should list them); migration guidance for re-routing a decision after it lands at the wrong scope.

### Sub-cluster initiative structure

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** A cluster in a reference implementation has stood up a substantial sub-structure — a deep multi-initiative sub-tree containing `artefacts/` (11 specs), an `initiatives/` set (initiative folders each with `README.md`, `decisions/`, `deliverables/`, `meetings/`, `updates/` subfolders), `processes/` (gates, handoffs, pod-model), `use-cases/` (3 use cases), `templates/` (5 templates for the initiative pattern), and `tracking/` (per-initiative tracking files). The cluster has effectively introduced its own local convention for organising multi-initiative work.

Whether this becomes a generalisable pattern depends on whether other clusters adopt similar shapes. At one instance, it is appropriately a cluster-local convention; the open-org-spec should not lift it into the standard prematurely. But the shape is rich enough to be worth tracking — particularly the `initiative/<name>/` schema (README + decisions + deliverables + meetings + updates), which has clear analogues to the existing `project` capability but operates at a sub-cluster scope.

**Trigger (OR'd — first fires).**

- A second cluster (in the reference implementation or another adopter) adopts a similar sub-cluster initiative structure. The shape that survives both instances is the candidate.
- An adopter outside the reference implementation asks how to model multi-initiative work inside a single cluster.
- The PD cluster's structure proves out to the point that another cluster wants to mirror it explicitly.
- The `project` capability is revised in a way that makes the sub-cluster initiative shape look like a special case of project (or vice versa) and the relationship needs naming.

**Context.**

- The pattern lives entirely under a single cluster's sub-tree. There is one sub-cluster (currently the only one), named for its operating model.
- Initiative folders follow a consistent shape: an `initiatives/<slug>/` with `README.md`, `decisions/`, `deliverables/`, `meetings/`, `updates/`. This mirrors the `project` capability's auxiliary files (`updates.md`, `decisions/`) but at a different scope.
- Templates exist in the sub-tree's `templates/` covering artefact, decision-record, meeting-summary, progress-update, use-case — i.e., the cluster has anticipated reuse of its own pattern.
- Use cases in the sub-tree's `use-cases/` cover engineering-led, PM-led, and infrastructure-autonomous variants — interesting framing because it grounds the structure in scenarios rather than abstract roles.

**If adopted.** Graduates as either a `cluster-initiative` capability or an extension of `project` for sub-scope use. The decision between the two depends on whether the second instance preserves the project-like shape or diverges from it. Until a second instance lands, the shape stays as a reference-implementation convention.

### Lean-by-default: a complexity-challenger for adopters

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** Organisations accumulate structure faster than they retire it. A cluster invents a sub-folder for an initiative; a sub-folder grows templates; templates fork variants; the variants outlive the initiative that motivated them. The standard's role is not to mandate how an adopter structures itself, but the standard should optimise for **lean adopters** — which means actively offering a way to challenge structure that has outpaced its justification.

The standard's existing posture is consistent with leanness — fog-of-war capability adoption, "don't restructure content to conform upfront," the rule that capabilities are derived from validated patterns — but the posture applies to the **standard itself**, not to adopters' own internal structure. A spec-driven adopter can become heavy under a lean standard. The gap is that the standard has no mechanism to push back when an adopter's structure outpaces its justification.

This is not a mandate. The standard would not tell adopters how to structure themselves. It offers a check — invoked by the adopter, on demand or at appropriate moments — that surfaces complexity signals and invites the adopter to challenge each one. The same fog-of-war discipline the standard applies to itself, made available to adopters for their own structure.

**Trigger (OR'd — first fires).**

- A second adopter introduces substantial sub-structure (sub-cluster, deep nesting, parallel directory tree) without an obvious second instance justifying it. The recurrence makes the gap visible across adopters.
- An adopter's repository accumulates folders / templates / scaffolding faster than the work the structure is supposed to organise — and the contributor running into this asks the standard for guidance.
- A reference-implementation prototype (slash command, agent, or other mechanism) earns its keep and the shape that worked is the candidate for graduation.
- A contributor in the reference implementation flags structure that exists but has no second instance — the kind of signal the challenger would surface — three or more times without resolution.

**Context.**

- Surfacing instance: a reference-implementation cluster's deep sub-structure (initiatives, artefacts, processes, templates, tracking). The shape is internally consistent but only one cluster has adopted it. Whether it is correct, premature, or an outlier is not yet evident — and there is no mechanism in the standard to surface that question at the right moment.
- Related signals worth tracking: empty subfolders with `.gitkeep` placeholders (intent to populate that may or may not materialise), templates without two-or-more usages, role spec hierarchies deeper than the recurrences justify, parallel module-level conventions where one would do.
- The standard's existing lean-bias is implicit. It is articulated in the README's "deliberately lightweight and fog-of-war" framing and in the `capability-lifecycle` spec's posture. It has not been articulated as an adopter-facing principle, nor as a mechanism adopters can invoke.
- Shape deliberately left open at this stage. Candidate forms include: a slash command (`oos:structure-check` or similar), an agent that posts findings to a feedback inbox at intervals, a heuristic checklist embedded in capability authoring guidance, or a check tool sibling to `adherence-check`. The right shape is a graduation-time decision once a prototype proves out — likely in the reference implementation first.

**If adopted.** Graduates as one of:

- A new capability (`complexity-challenger` or similar) under `specs/`, with the mechanism defined and an invocation pattern.
- A section addition to `adherence-check` covering "structure complexity" signals — broader scope, but ties two checking concerns together.
- A standard-level principle articulated in `README.md` or `GUIDE.md` (lean-by-default for adopters, not just for the standard), plus a reference-implementation prototype that adopters can copy. Lighter weight; preserves standard agnosticism about mechanism.

The decision between these depends on what shape proves out in the reference implementation first. Until then, the entry preserves the observation that the lean-by-default bias should propagate from the standard to its adopters, with the mechanism kept open.

### Artefact taxonomy: demand-vs-supply as a standard-level concept

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** A reference implementation has just landed a repo-wide demand-vs-supply ADR establishing a routing principle: cluster-origin demand artefacts live under the operating-team scope, cross-cutting infrastructure supply guidance lives under the infrastructure scope. The principle is not adopter-specific — any organisation with a cross-cutting infrastructure team and domain-specific operating teams has the same split between *what the operating teams need* (demand) and *how the infrastructure team delivers* (supply). The reference implementation invented the principle to resolve real routing ambiguity; the standard could articulate the conceptual split so future adopters do not each re-invent it.

This entry is **broader than** the earlier "Decision routing across scopes" entry above. That entry asks how decisions specifically route between scopes (project vs cluster vs Factory vs repo-root). This entry generalises: how does any artefact route based on which side of the operating boundary originates it (demand-side, who needs the work) versus which side delivers it (supply-side, who provides the means)? Decisions are one artefact-kind subject to that taxonomy; capability matrices, friction rankings, role specs, and tooling recommendations are others.

**Trigger (OR'd — first fires).**

- A second adopter independently invents a demand-vs-supply (or analogous) split between operating teams and a cross-cutting infrastructure team, and asks the standard for guidance.
- A third or fourth reference-implementation ADR codifies a routing rule that fits the same taxonomy (e.g., the "Decision routing across scopes" entry above graduates and recapitulates the same principle for decisions specifically).
- A reference-implementation contributor reaches for the standard to resolve a routing question and finds nothing — i.e., the gap is felt outside the immediate demand-vs-supply ADR conversation.
- An adopter outside the reference implementation reports difficulty distinguishing what to author at the cross-cutting infrastructure scope vs the operating-team scope.

**Context.**

- Surfacing artefact: a reference implementation's repo-wide demand-vs-supply ADR. Names the principle, the four kinds of artefacts it distinguishes, and the consequence that roles can span both surfaces with two role specs rather than one blended one.
- Standard's existing surface for this: nothing direct. `governance-at-scope` defines who decides at each scope but says nothing about how artefacts route based on origin. The `project` capability says nothing about which side of the demand/supply boundary a project sits on, beyond an optional `Cluster:` field in the schema.
- The "Decision routing across scopes" entry above is the narrower precedent — it observes the same gap for a specific artefact-kind. Co-graduating both entries is plausible: the broader taxonomy lands first, and the decision-routing entry becomes its first concrete application.
- Related conceptually to the "Sub-cluster initiative structure" entry above: that entry observes a multi-initiative pattern inside a cluster; the demand/supply taxonomy may help name what kinds of initiatives belong inside clusters versus what belongs at the Factory.

**If adopted.** Graduates as one of:

- A new capability (`artefact-taxonomy` or `routing`) under `specs/`, defining the demand-vs-supply distinction, the kinds of artefacts each side typically produces, and the role-spans-both-surfaces pattern.
- A section addition to `governance-at-scope/spec.md` covering "what kinds of artefacts route to which scope," subsuming the decision-routing entry above as a specific application.
- A standard-level principle articulated in `README.md` or `GUIDE.md`, with adopter-side guidance on how to map their own folder structure to the taxonomy. Lighter weight; preserves standard agnosticism about specific paths while naming the conceptual split.

The decision among these depends on how much shape the taxonomy needs to take. If just the principle, a section addition or README articulation is right. If a fuller taxonomy with named artefact-kinds (demand-synthesis, supply-guidance, operating-model, source-context), a new capability spec is the natural home.

### [Graduated] People-as-spec: per-module `people.md` as a standard-level concept

**Added:** 2026-04-30 by Javier Fernandez
**Graduated:** 2026-05-22 → [`specs/people/spec.md`](./specs/people/spec.md)

**Rationale.** All three clusters in a reference implementation carry a `people.md` file with a consistent shape: a cluster-lead table (Name / Role / Authority), a core-working-group or functional-leaders table mapping people to workflows or functions, a current-org or FTE-baseline table, and optional future-state role-design and last-verified-date fields. Three independent instances — one per cluster — all converge on the same shape. That convergence is what the standard's fog-of-war threshold cares about: a pattern that repeats across instances without coordination has earned its keep.

The pattern is cluster-domain (per the reference implementation's demand-vs-supply ADR): `people.md` describes who is in the cluster, what they do, and what authority they hold over its specs. Today the convention is implicit; an adopter introducing a fourth cluster (or another adopter introducing their first) has no canonical shape to follow.

**Trigger (OR'd — first fires).**

- A fourth instance lands (e.g. a future cluster in the reference implementation, or another adopter inventing the pattern independently).
- A contributor authoring a new module's `people.md` produces a divergent shape because there is no canonical reference, and the divergence introduces friction (tools reading across `people.md` files break, or the local convention contradicts what other clusters do).
- A tool is proposed that queries people across modules — ownership lookup, capacity model, role-aware orientation — and benefits from a defined schema.
- The `governance-at-scope` capability is revised for any other reason; a `people.md` section is the natural co-revision because authority and ownership are governance-adjacent.

**Context.**

- Live instances in a reference implementation: a `people.md` in each of its three clusters.
- Common shape:
  - **Cluster lead** — table of Name / Role / Authority. The Authority field describes what the lead can edit and what they are accountable for.
  - **Core working group** or **Functional leaders** — table mapping people to workflows or functions in scope.
  - **Current org / FTE baseline** — table of role / FTE / band.
  - Optional: **Future-state role design**, **Notes**, **Last verified** date.
- Variants observed: one cluster's `people.md` previously had multiple co-leads; corrected on 2026-04-30 to a single Cluster Lead. The single-lead shape is the convergent state across all three.
- **README↔people.md drift risk.** A repo-level clusters README carries a "Participants" column with a short list of names per cluster, while each cluster's `people.md` carries a full working-group table that includes those names and more. The two are hand-maintained, do not align, and have no rule defining how the README's subset is chosen. Same drift smell as the "Updates-ledger as a projection" entry above. A `people` capability spec would resolve it by naming a single source of truth (per-module `people.md`) and either eliminating the README "Participants" column, defining what subset it projects, or generating it from `people.md` automatically.
- Demand-vs-supply implication: `people.md` is cluster-domain demand-side (it describes the cluster's own structure). Any standard-level spec for it sits with cluster-domain rules, not infrastructure-supply.

**If adopted.** Graduates as one of:

- A new `people` capability under `specs/`, defining the file-location convention (`<module>/people.md`), the table shapes, and what each table represents. Most explicit; gives an adopter a clean shape to instantiate.
- A section addition to `specs/governance-at-scope/spec.md` covering "people who hold authority at this scope" — ties into the existing governance-owner schema and avoids creating a new capability.
- A standard-level convention articulated in `GUIDE.md` with reference-implementation examples. Lightest weight; preserves adopter agnosticism about specific table contents.

The decision among these depends on how prescriptive the standard wants to be about people-data. If just the location and a minimum schema (lead table mandatory, working group optional), a section addition fits. If a richer schema with role/FTE/authority semantics, a new capability is the natural home. The convergence in the reference implementation suggests the capability route — but the convergence is between three modules of the same adopter, so cross-adopter validation is still pending.

### Capability-first authorship as a standard-level concept

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** A reference implementation has just landed a capability-governance ADR refining the demand-vs-supply split for the specific class of *capabilities* (and their narrower form, *skills*). The principle: a capability has multiple consumers by definition; placing it within any one consumer's path biases its design against the others; therefore capability governance — authorship of the spec, lifecycle status, promotion and retirement criteria — sits with the cross-cutting infrastructure team regardless of who contributes content.

The principle is not adopter-specific. Any organisation with a cross-cutting infrastructure team and operating teams that surface reusable patterns will encounter the same coupling risk: a skill, agent, library, or process spec drafted in the operating team's path implicitly inherits that team's governance, biasing its design against the other consumers it is supposed to serve. The reference implementation's capability-governance ADR articulates the rule for its scope; the standard could articulate it generically so adopters do not each re-invent the principle (or worse, never realise the principle is needed and silently couple their reusable artefacts to local owners).

**Trigger (OR'd — first fires).**

- A second adopter independently invents a capability-governance rule equivalent to the reference implementation's.
- A reference-implementation contributor reports drift between an operating-team-side capability artefact and an infrastructure-side equivalent — i.e., the dual-maintenance smell the capability-governance ADR was meant to prevent surfaces despite the rule.
- The "Artefact taxonomy: demand-vs-supply as a standard-level concept" backlog entry above graduates and the capability-governance principle becomes its first concrete sub-rule worth specifying.
- An adopter outside the reference implementation reports difficulty deciding whether a reusable pattern they are authoring belongs in their immediate team's path or in a cross-cutting infrastructure path.

**Context.**

- Surfacing artefact: a reference implementation's capability-governance ADR. Names the principle, four operational consequences (capabilities live at infrastructure scope; cluster contribution flows through the infrastructure team; demand-side artefacts describing needs remain cluster-domain; lifecycle transitions are infrastructure-decided), and rationale.
- Concrete instance: 11 skill specs shipped under a cluster's deep sub-tree before the rule existed. The capability-governance ADR explicitly preserves them pending the infrastructure owner's consolidation decision; the principle applies to new artefacts.
- Closely related backlog entries above: "Artefact taxonomy: demand-vs-supply as a standard-level concept" (broader principle the capability-governance ADR refines for capabilities); "Lean-by-default complexity-challenger" (the audit mechanism that would surface routing violations like a skill under a cluster path).

**If adopted.** Graduates as one of:

- A new capability under `specs/` (e.g. `capability-authorship`) defining the rule, the contribution flow, and the lifecycle decider role.
- A section addition to a future `artefact-taxonomy` capability (if the broader entry above graduates first), with capability-governance as its most-specified sub-rule.
- A standard-level principle in `README.md` or `GUIDE.md` plus reference-implementation examples; lighter weight; preserves adopter agnosticism.

The decision among these depends on whether the standard wants to specify capability lifecycle as a structured concept (capability with promotion/retirement state machine, contribution flow, lifecycle decider) or just the placement principle. The reference implementation's capability-governance ADR already names lifecycle transitions as a decider responsibility — suggesting the structured route is plausible.

### Agent-surfaced principle feedback to contributors

**Added:** 2026-04-30 by Javier Fernandez

**Rationale.** A spec-driven repository accumulates principles — atemporal-vs-lifecycle, instruction-not-deliverable, capability-first, demand-vs-supply — that govern how contributions should be shaped. In a fully manual contribution flow, principles live in a contributor-instructions file and contributors are expected to read them. In an LLM-mediated contribution flow (which this standard targets), a different mechanism is possible: the agent observes a contributor's intent and surfaces the relevant principle *before* the contribution lands, in plain language, with the contributor's specific action as the example. A reference implementation already exhibits this passively — an agent reads the contributor-instructions file before editing — but the trigger conditions, phrasing norms, and persistence (does the feedback land in a feedback file? in chat only? as an inline comment in a PR?) are unspecified.

The same surface should also handle *positive* reinforcement when a contributor makes a non-obvious correct choice — surfacing why the choice is right and connecting it to the principle, so the contributor learns rather than just complies. Today this is implicit; specifying it would let any agent across any adopter behave consistently.

This entry was raised during a session on 2026-04-30 in the context of the capability-first principle (a reference implementation's capability-governance ADR), where the question arose: *"How can I ensure that an agent is providing this feedback?"* The session noted three response shapes — passive (contributor-instructions file alone), on-demand (slash command), automatic (hook) — and deferred the design to a backlog entry. This is that entry.

**Trigger (OR'd — first fires).**

- A second principle accumulates that needs agent enforcement and the ad-hoc mechanism (agent reads the contributor-instructions file and *might* say something) starts producing inconsistent behaviour across sessions.
- An adopter outside the reference implementation reports that their agent does not catch obvious principle violations even though the principles are documented in the contributor-instructions file.
- The "Lean-by-default complexity-challenger" backlog entry above graduates and the design needs to handle behaviour-based feedback alongside structural feedback.
- A reference-implementation contributor asks for a specific kind of feedback (e.g., *"warn me when I'm about to author a skill outside the cross-cutting infrastructure scope"*) and the absence of a specified mechanism becomes friction.

**Context.**

- Surfacing question: the capability-governance ADR lands a behaviour rule (capability-first); the question arises of how an agent enforces it. The contributor-instructions routing line is the immediate mechanism, but it relies on the agent noticing — there is no specified protocol.
- Closely related backlog entries: "Lean-by-default complexity-challenger" (mechanism for surfacing structural complexity); "Capability-first authorship as a standard-level concept" (principle the agent would enforce); "Two-layer representation" (the structured catalogue an agent might consult to detect violations cheaply).
- A reference implementation's contributor-instructions file already includes some behaviour-shaping rules (*"Convert relative dates to absolute,"* *"Don't create new .md files without asking,"* *"Distinguish content from governance-mandated structure"*). These are the seed; the gap is that there is no protocol for *how* the agent surfaces a violation when it occurs.
- Three shape candidates kept open per the lean-by-default entry: passive (contributor-instructions guidance the agent applies), on-demand (slash command like `/principle-check`), automatic (SessionStart hook or pre-commit). The behaviour-feedback question generalises across these — each shape needs phrasing norms, persistence, and tone guidance.
- **Live instance (2026-05-22):** the `people` capability (graduated from backlog) introduced a five-column `people.md` shape for standing membership at any scope. In practice, contributors have been declaring roles by creating standalone role spec files (e.g. a cluster-group lead role spec) or adding `Owner:` headers in arbitrary files — valid in isolation, but none of them triggered a prompt to also update `people.md`. The correct agent behaviour: when a contributor declares a role at a scope (adding `Owner:`, creating a role spec, adding themselves to a `people.md`), the agent recognises the trigger and routes them to the five-column shape. This is the clearest in-the-wild example of agent-surfaced principle feedback — a routing rule that should fire on a contributor action, not just when the contributor thinks to ask.

**If adopted.** Graduates as one of:

- A new capability under `specs/` (e.g. `agent-feedback`) defining when an agent surfaces a principle, how to phrase it, where to persist it (chat, feedback file, PR comment), and the tone (corrective, educational, neutral).
- A section in `governance-at-scope` covering how scope-level principles propagate through agent feedback to contributors authoring at that scope.
- A standard-level convention in `GUIDE.md` plus reference-implementation examples, with no fixed mechanism but a published phrasing template adopters can copy.
- Merges into the "Lean-by-default complexity-challenger" entry above if both are mechanism questions for the same agent class.

The decision among these depends on whether the standard wants to specify agent behaviour (more prescriptive, may not generalise across LLM interfaces) or just the principle-broadcast convention (more permissive, lets each adopter's agent implement). The reference implementation's experience with `/catchup` and `/ingest` suggests adopter prototypes earn shape first; the standard graduates the shape that works.

### [Graduated] Adopter-side tooling as a governed artefact category

**Added:** 2026-05-05 by Javier Fernandez
**Graduated:** 2026-05-22 → [`specs/tooling/spec.md`](./specs/tooling/spec.md) + [`specs/tooling/catchup/spec.md`](./specs/tooling/catchup/spec.md)
**Subsequent extensions (same day):**
- [`specs/tooling/adhere-to/spec.md`](./specs/tooling/adhere-to/spec.md) — second tool under the capability; conformance-scanning + command-wiring mechanism that materialises capability activation.
- `tool_extensions` map in the adoption manifest — per-tool adopter overlay mechanism letting an adopter extend a specific tool (e.g., catchup) without restating tooling-wide concerns. See [`decisions/2026-05-22-tool-extensions-in-manifest.md`](./decisions/2026-05-22-tool-extensions-in-manifest.md). First exercise: a reference implementation's catchup extension.

**Rationale.** The standard treats certain artefact categories as first-class — capabilities, projects, decisions, governance, principles. It does not treat *tooling* as a category. By "tooling" here I mean the heterogeneous set of artefacts that operate *against* a conformant repo: slash commands (`.claude/commands/*` in Claude Code adoptions, equivalent in other LLM interfaces), subagents (`.claude/agents/*`), hooks (`SessionStart`, `PreCommit`, etc.), skills, MCPs, standalone scripts. These artefacts have accumulated in a reference implementation — four UX affordances under one parent thesis: a catchup tool, an ingest tool, an onboard tool, and a scan-channels tool — without standard-level guidance on where they live, who owns them, how they're versioned, how they discover each other, or how they relate to the spec content they operate against. Each tool has been authored as an ad-hoc v0 project; the post-v0 fate of any single tool is unspecified.

The gap is asymmetric. *Standard-side* tooling — commands the standard itself ships, like `oos:adopt-governance` — has implicit conventions (co-located with the capability spec it serves). *Adopter-side* tooling has none: an adopter inventing their second slash command has no canonical location, no naming convention, no relationship rule between commands, no shared protocol for role detection or repo-state inspection. The narrower partial precedent in this backlog — `Command protocol for oos: commands` (2026-04-24) — covers standard-side commands only.

The pattern is not adopter-specific. Any organisation adopting the standard and operating it through an LLM interface will accumulate adopter-side tooling. Without standard-level guidance, every adopter re-invents the conventions; tools authored by different contributors within one adopter risk inconsistency; cross-adopter tool reuse becomes accidental. A standard-level concept of tooling — the governed artefact category, the location convention, the versioning and lifecycle, the relationship rules — would let adopters compose tools deliberately rather than ad-hoc.

This entry supersedes a narrower draft scoped to a single affordance (channel-to-spec sync via `/scan-channels`). The narrower scope captures one tool; the broader scope captures the gap that explains why that tool — and three siblings — were each authored without a canonical home.

**Trigger (OR'd — first fires).**

- A second adopter independently invents adopter-side tooling against their conformant repo and asks the standard for guidance on where it lives, who owns it, or how it should be structured.
- Any of the four reference-implementation v0 affordances (catchup, ingest, onboard, scan-channels) reaches its close outcome and the post-v0 fate question — does the tool graduate to a standalone tooling spec? does it stay a project? does it merge into a shared affordance capability? — needs answering.
- A reference-implementation contributor opens a tool that overlaps with an existing one (duplicate role-detection logic, parallel discovery mechanism, conflicting state-baseline conventions) and the conflict surfaces the absence of a relationship rule.
- An adoption-level skills working session in a reference implementation reaches a conclusion that surfaces what an adopter-side tooling spec *would* need to cover at the standard level. The adoption-level decision is logically downstream of the standard-level concept; if it lands first, the standard would need to retroactively articulate the principle the adoption is already operating under.
- A tool is proposed against the standard that would query tooling state (a tooling catalogue, an adherence check that flags tools without owners, a structure-complexity audit per the *Lean-by-default* entry above).
- The narrower `Command protocol for oos: commands` entry above graduates and the asymmetry between standard-side and adopter-side tooling becomes the natural co-revision.

**Context.**

- Live instances in a reference implementation: a catchup tool, an ingest tool, an onboard tool, and a scan-channels tool — four UX affordances under a single parent thesis project. Each ships a slash command in the adopter's LLM-interface command directory. All four reuse the same role-detection logic; none of them declares this reuse formally — the shared primitive lives implicitly in the orientation command and is referenced by the others, but the "shared layer" has no canonical home.
- Other tooling outside the affordance set: the adopter's command directory carries additional commands; a subagents directory carries subagents; a SessionStart hook triggers the catchup tool on session start. These are runtime-resolvable but not specified at the standard level.
- Adoption-level concurrent work surfacing the same gap: a reference implementation's skills-README placeholder (2026-05-05) names skills as a governed category at the cross-cutting infrastructure scope, with the capability-governance ADR handing capability/skill governance to the infrastructure team. The skills working-session prompt — *"do we need to converge skills, yes/no, why?"* — is the adopter-side question of where adopter-side tooling lives, governed by whom. The standard-level question subsumes it: until the standard articulates a tooling concept, every adopter resolves this independently.
- Closely related backlog entries above:
  - **Command protocol for `oos:` commands** — narrower, standard-side-only. Likely co-graduates or merges; see open question 2 below.
  - **Two-layer representation** — a structured catalogue could hold tooling metadata (owner, version, status, role-detection function) cheaply; tools that introspect tooling state benefit from it.
  - **Adopter-state detection protocol for commands** — the shared primitive multiple commands need; pairs naturally with a tooling concept that includes shared protocols.
  - **Capability-first authorship** — tools that have multiple consumers cannot be governed by any one consumer; the same principle that landed for capabilities applies to tooling.
  - **Lean-by-default complexity-challenger** — the audit mechanism that would flag tools without owners or duplicate tools.
  - **Agent-surfaced principle feedback** — same class of LLM-mediated affordance; a tooling concept would cover behaviour-feedback affordances alongside slash commands.
- Asymmetric maturity across tool types: slash commands have the most live instances (≥4); subagents, hooks, skills, MCPs each have fewer or none in the reference implementation. The entry intentionally leaves the per-type specification open until each type has accumulated enough instances to earn its keep — see open question 1 below.

**Open questions.**

These are scope decisions left intentionally open. The right answer to either may be visible only at graduation time, when the reference-implementation evidence is in.

1. **One category or many?** Tooling as listed (slash commands, subagents, hooks, skills, MCPs, scripts) is heterogeneous — different deployment mechanisms, different governance concerns, different lifecycles. The right shape may be a single `tooling` capability with sub-types named but not specified, or multiple capabilities (one per type) that share common ancestry (location convention, ownership pattern, role-detection reuse). The trade-off is clarity vs prescription: one category captures the cross-cutting principle (tooling is a governed artefact); multiple categories let each type develop the specifics it needs. The reference implementation today has critical mass only on slash commands; specifying the other types prematurely is an error the standard's lean-by-default bias warns against. Lean is *one entry, one category, sub-types named but not specified* — but the alternative is defensible.

2. **Cross-reference or merge with `Command protocol for oos: commands`?** That entry covers standard-side commands; this one covers adopter-side tooling. Plausibly they co-graduate as one capability covering both surfaces — same shared primitives (location, discovery, state inspection) apply to both — or stay distinct, with the adopter-side entry referencing the standard-side conventions where they diverge. The merge decision depends on whether the standard-side and adopter-side cases share enough mechanism to warrant a single spec or whether the standard-side specifics (`oos:` prefix protocol, capability co-location pattern) deserve their own home. Lean is *cross-reference, defer the merge decision to graduation time*; the existing entry is narrower and earlier, and merging now risks losing the standard-side specifics it captures.

**If adopted.** Graduates as one of:

- A new `tooling` capability under `specs/`, defining: the artefact category and its sub-types; the file-location convention (per-scope `tooling/<name>/`, or co-location with the spec the tool serves); the ownership pattern (per capability-first authorship: tooling with multiple consumers is governed at infrastructure scope); the lifecycle (v0 / promotion / deprecation / retirement, parallel to `capability-lifecycle`); the relationship rules (when two tools share a primitive, the primitive lifts to a shared layer); the discovery protocol (how an LLM resolves a command/agent/hook reference to its definition).
- A section addition to a future `affordances` capability if `/catchup`, `/ingest`, `/onboard`, `/scan-channels` graduate together — tooling becomes the broader category that affordances are one shape of.
- A standard-level convention articulated in `GUIDE.md` plus reference-implementation examples, with no fixed mechanism but a published tooling-protocol template adopters can copy. Lighter weight; preserves adopter agnosticism about which LLM interface and tool deployment mechanism is being used.

The decision among these depends on whether the standard wants to specify tooling shape (more prescriptive — would constrain adopters with a different tool vocabulary) or just the governance principle and location convention (more permissive). The reference implementation's experience across all four affordance v0s, plus the adoption-level skills working-session outcome, will inform the right level of prescription at graduation time.
