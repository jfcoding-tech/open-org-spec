# Catchup

A tool of the open-org-spec tooling capability. Orients a returning contributor to what changed in the repository since their last contribution — surfacing what touches their own specs first, then shared operating-model changes, then everything else.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** an adopter executes the base spec via a relay at their command directory (e.g. `.claude/commands/catchup.md` for Claude Code adopters), extended at `.open-org-spec/extensions/tooling/catchup/spec.md` to declare adopter-specific behaviours such as multi-repo, contributor-mode, channels, and team-status nudges.

## Purpose

Contributors return to a spec-driven repository after gaps — days, weeks, or longer. Without orientation, they either re-read the full diff (slow) or miss changes that affect work they own (risky). The catchup tool provides a structured briefing: start with what is most relevant to this contributor, end with the rest.

The output is not a git log. It is a prioritised digest designed to answer: *"What do I need to know before I start working today?"*

## Pattern

### Inputs

- **Contributor identity** — resolved from `git config user.name` and `user.email`. Used to find the contributor's baseline and detect which specs they own.
- **Contributor mode** — adopters may define modes (e.g. engineer vs non-engineer) that change whether the tool auto-pulls before running. Mode detection is an extension point; the generic spec does not prescribe modes.
- **Baseline** — the most recent commit authored by this contributor on the current branch. If none exists, fall back to the merge base with the main branch.

### Step 0 — Sync state

Fetch from the remote before anything else (`git fetch`). Fetch is non-mutating and safe in all modes.

Surface the sync state as the first line of the output when it has something to say:
- Remote ahead → tell the contributor how many changes are on the remote and that the digest reflects them.
- Local unsaved work → nudge to save before pulling.
- Fetch failed → note the digest is from the local copy.
- Up to date → silence. No line needed.

Adopters may extend this step to auto-pull for contributor modes where manual git is not expected.

### Step 1 — Compute the digest window

List all commits from the baseline to the digest tip (the fetched upstream when ahead; otherwise local HEAD). These commits form the digest window.

If the window is empty: output **"You're caught up."** and stop.

### Step 2 — Bucket changed files

For each commit in the window, gather the files it touched. Assign each file to one of three buckets:

- **A — Yours.** Files where the contributor is named in a role header at or above the file's path. Role headers include: `Owner:`, `Lead:`, `Driver:`, `Approver:`, and any equivalent authority or accountability marker defined by the adopter. Record the specific role — do not flatten to a generic "yours".
- **B — Shared model.** Files that define how the whole repository operates. Two layers:
  - **Standard-level** (always bucket B regardless of adopter) — the standard's own normative content under `open-org-spec/specs/` (capability and tool definitions, including `<capability>/spec.md`, `<capability>/<verb>.md`, and `tooling/<tool>/spec.md`) and any adopter extensions under `.open-org-spec/extensions/`. A change to *how a capability works* affects every contributor against any conformant repo; surfacing it in bucket B means each contributor's next catchup TL;DR explains what moved at the standard or extension level, without per-owner feedback labor.
  - **Adopter-level** (declared by the adopter's catchup extension) — typically the top-level README, the contributor guide (CLAUDE.md equivalent), module READMEs, governance files. The adopter chooses this set.
  - Both layers surface regardless of contributor.
- **C — Everything else.** Grouped by commit.

### Step 3 — Scan feedback files

For any `feedback.md` file in the digest window, scan for entries addressed to this contributor (by name). Surface matched entries as an **inbox** — before bucket A, because inbox items are pending a response, not just informational.

Per the [`feedback-inbox`](../../feedback-inbox/spec.md) capability: entries carry an explicit addressee marker (e.g. `→ <name>`). Only entries added within the digest window surface — not every open item in the file.

### Step 4 — Check uncommitted work in owned paths

Walk the working tree. For any modified or untracked file under a path where the contributor holds a role, surface it as in-progress work under bucket A. Uncommitted work in owned paths is often the most relevant thing a contributor needs to see.

### Step 5 — Output

Scale the shape to the change set:

- **TL;DR first** — 1–2 sentences answering *what moved and why*. Read the touched spec's purpose statement to extract intent; do not paraphrase the commit message. Surface thesis connections: if a changed spec names the contributor's own work as a parent, name that connection in the TL;DR.
- **Inbox** (if non-empty) — one line per entry, with the core ask and an explicit action.
- **Bucket A — Yours** — one line per file, with author, date, and an explicit action verdict. Every entry ends with an action; `no action` is a valid verdict but must be stated.
- **Bucket B — Shared model** (if not already covered by TL;DR) — one line per file.
- **Bucket C — Other** (if not already covered by TL;DR) — grouped by commit.
- **Close** — one line inviting feedback.

Never render an empty bucket. Never repeat what the TL;DR already said.

### Extension points

Adopters extend the generic pattern with org-specific context. Common extensions in the reference implementation:

- **Multi-repo support** — a private repo mounted at a known path runs steps 1–4 in parallel, with paths tagged to distinguish repos.
- **Contributor modes** — auto-pull in non-engineer mode; fetch-only in engineer mode.
- **Additional role headers** — adopters add their own authority markers to bucket A detection.
- **Channels nudge** — if the adopter's clusters have live communication channels, a lightweight existence check surfaces activity since the baseline.
- **Factory nudge** — if the contributor is part of a cross-cutting infrastructure team, a nudge to a team-status command surfaces active projects.

## What is not prescribed

- **The specific git interface.** The pattern describes fetch, log, and show operations generically; the implementation uses whatever git tooling is available.
- **How contributor modes are defined.** Mode detection is an extension point. The generic spec does not prescribe engineer vs non-engineer or any other mode taxonomy.
- **Which files are "shared model".** The adopter defines which files govern the whole repository; the generic spec names the concept and leaves the file list to the implementation.

## Rationale

A returning contributor's first question is not "what commits landed?" — it is "what do I need to know?" Those are different questions. A git log answers the first; catchup answers the second by applying the contributor's role context to the raw change set and surfacing what matters to them specifically.

The two structural choices — baseline from the contributor's last commit, and bucket A driven by role headers rather than file paths — are what make the output personalised rather than generic. Role-based bucketing means the contributor does not need to know which files they own; the tool infers it from the repo's own ownership declarations.

## Adoption

Adopters activate `catchup` by wiring a relay at their command directory (e.g. `.claude/commands/catchup.md` for Claude Code adopters) pointing to this spec, and optionally declaring an adopter extension via the manifest's `tool_extensions` mechanism (see [`../../adoption-manifest/spec.md#per-tool-extensions`](../../adoption-manifest/spec.md#per-tool-extensions)). The relay reads this spec; the agent loads any declared tool extension automatically.

Worked example: an adopter wires a relay at their command directory (e.g. `.claude/commands/catchup.md`), an extension at `.open-org-spec/extensions/tooling/catchup/spec.md`, and declares it in `.open-org-spec/config.yaml` under `tooling.tool_extensions.catchup`.

*(An `oos:adopt-catchup` command that scaffolds the relay and an empty extension file is deferred until a second adopter instance.)*

## Related

- [`../spec.md`](../spec.md) — parent tooling capability.
- [`../../feedback-inbox/spec.md`](../../feedback-inbox/spec.md) — the inbox scanning in step 3 depends on this capability's addressee conventions.
- [`../../people/spec.md`](../../people/spec.md) — role detection in step 2 depends on the people-at-scope shape.
- Reference implementation: an adopter's `catchup` command relay (e.g. `.claude/commands/catchup.md`) and a closed validating project that graduated the tool into this capability.
