# open-org-spec

An open standard for applying **spec-driven development** to **organisational design**.

Published under the [MIT License](./LICENSE). Copyright (c) 2026 Busuu Ltd. Created by [Javier Fernandez](./AUTHORS).

> **Start here if you are an LLM / agent.** If you've been asked to set this standard up in an organisation's repository, read and execute [`specs/adoption-manifest/adopt.md`](./specs/adoption-manifest/adopt.md) (`oos:adopt-manifest`). It is the autonomous bootstrap — it scaffolds the adoption manifest, generates the repo's contributor guide, and activates the capabilities the adopter chooses, in one run. It asks only for the handful of inputs it cannot infer (owner, a one-line org description, which capabilities to activate); it edits no files by hand. You do not need to follow the human-oriented checklist below — it describes the same flow. See also [`AGENTS.md`](./AGENTS.md).

## Purpose

Organisations are systems. Like software systems, they benefit from being described explicitly — with intent, constraints, ownership, and conventions written down — rather than implicitly understood. An organisation that has written itself down this way becomes **observable**: its decisions findable, its ownership named, its complexity queryable rather than locked in people's heads.

`open-org-spec` is a **meta-spec**: a standard that defines *how* an organisation describes itself. It does not prescribe what any particular organisation should look like. Each organisation authors its own specs (in its own repository) conformant with the standard, and adapts the conventions to its own context.

The standard is deliberately lightweight and fog-of-war: conventions are codified only when a real use case demands them. Capability specs under `specs/` are added one at a time, inspired by OpenSpec's shape but not bound to it — the standard adopts what's useful and adapts what isn't.

## Architecture

Two kinds of repositories use this standard:

1. **This repository** — the standard itself. Versioned. Each capability is described in its own spec under [`specs/`](./specs/).
2. **An organisation's repository** — an instance of the standard. References a specific version of open-org-spec and contains that organisation's current specs, in-flight work, and decisions.

## Contents

- [`specs/`](./specs/) — the capabilities that make up the standard. Each capability is a folder with its own `spec.md`. Current capabilities:
  - `governance-at-scope` — governance folders, DACI, decisions at any scope
  - `project` — time-boxed initiatives with lifecycle gates
  - `people` — role rosters and authority declarations at any scope
  - `feedback-inbox` — structured feedback and nudge routing
  - `function` — cross-cutting business functions (Revenue, Marketing, Finance, etc.)
  - `adoption-manifest` — manifest schema, capability activation, extensions
  - `capability-lifecycle` — proposing and applying changes to the standard
  - `tooling` — commands, agents, hooks; includes `agent`, `catchup`, `spec-health`, `adhere-to`
  - `observability` — org-health metrics and contributor activity dashboards
  - `adherence-check` — conformance reports against any active capability
  - `federation` — how multiple adoptions relate: sibling repos, probe-based access, spillage contract, ephemeral aggregation
- [`templates/`](./templates/) — copy-paste starters for artefacts defined by the capabilities in [`specs/`](./specs/).
- [`WHY.md`](./WHY.md) — why an organisation would adopt this: the problem, the pattern, and what it looks like in practice.
- [`GUIDE.md`](./GUIDE.md) — how to use the standard in an organisation.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to contribute to the standard itself (commit conventions, versioning, promotion checklist).
- [`backlog.md`](./backlog.md) — deferred work against the standard itself.

## Getting started (for adopters)

The standard is inert until an organisation's repository adopts it. Five steps take you from an empty repo to a working, LLM-enforced adoption:

1. **Bring the standard into your repo.** Add `open-org-spec/` as a git submodule, subtree, or vendored copy at your repository root. Pin to a version (see [Status](#status)).
2. **Drop in the agent instructions — at your interface's path.** Copy [`templates/CLAUDE.md`](./templates/CLAUDE.md) to the file your LLM interface actually reads: `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `.cursor/rules/` for Cursor (see the [interface table](./specs/adoption-manifest/adopt.md#interface-conventions)). Fill in the `<placeholders>`. This is the file that makes the standard *operate*: the agent reads it every session and enforces the active capabilities. (The autonomous bootstrap in step 4 does this for you, at the right path for your interface.)
3. **Scaffold the manifest.** Create `.open-org-spec/config.yaml` declaring which capabilities you're activating, at what `standard_version`, and who owns the manifest. See the [adoption-manifest spec](./specs/adoption-manifest/spec.md) for the schema.
4. **Activate your first capability.** Set a capability's `status: active` in the manifest and run `adhere-to <capability>`. It scans your repo, lists conformance gaps, and routes each to its owner. Activation is complete when gaps are conformed or recorded as known follow-ups.
5. **Wire your first tool.** Activation scaffolds thin command relays in your LLM interface's command directory and lists them in that directory's README, so contributors discover them in one place.

Capabilities are **opt-in and incremental** — activate one when a real use case demands it, not all upfront. Start with `governance-at-scope` if you have governance content, or `people` if you maintain team rosters. [`GUIDE.md`](./GUIDE.md) explains the philosophy behind this incremental, fog-of-war approach.

## Status

Early and deliberately incomplete. Version: **0.18.1**. The standard grows from real use cases; breaking changes are expected until it stabilises.

- **0.17.0** — **breaking** — `risk-at-scope`: required `## Log` section on all risk records. Every `disposition_at` change, status transition, and owner reassignment requires a dated log entry explaining what was decided. Scanner gains Step 3 (log conformance check) writing `[log-absent]` and `[log-missing]` requests to owner feedback inboxes. `adherence-check` gains `gap`/`violation` checks for the new requirement. `/new-risk` scaffolds the section on creation. Reference git pre-commit hook added at `specs/risk-at-scope/implementations/hooks/`. Existing risk files require a one-time backfill.
- **0.8.0** — `federation` capability: how multiple adoptions of the standard relate. Introduces sibling-repo model (no nesting), probe-based access via git submodule init, standalone-capability hard requirement for members, personal-member type, three-rule spillage contract (scope-writes-to-source, probe-don't-configure, aggregate-ephemerally), and information-flow constraint (one-directional for org members; two-directional explicit action for personal members).
- **0.2.0** — **breaking** — agent restructuring and naming. Dropped the `-agent` suffix everywhere (agents are named for what they do). `catalogue` extracted from spec-health to a standalone tooling capability (`specs/tooling/catalogue/`) emitting a split catalogue: `index.yaml` discovery manifest + per-type sub-files (`specs.yaml`, `decisions.yaml`, `feedback-inboxes.yaml`, `projects.yaml`). `decision-nudge` → `decision-escalation`, moved to `specs/governance-at-scope/tools/` and generalised to route a disposition request (confirm/defer/reassign). The observability agent → `agent-metrics` (`specs/tooling/agent-metrics/`), now measuring all agents and commands, not just spec-health. Spec-health suite reduced to `conformance` + `catalogue` (the latter a referenced standalone capability). Observability capability tools renamed: `owner-load`→`owner-health`, `inbox-load`→`inbox-health`, `decision-flow`→`decision-health`, `spec-touch`→`spec-activity`. Delta-mode optimisation pattern defined in `tooling/spec.md`.
- **0.1.6** — artefact scaffolding schema: `adhere-to` Step 4 generalised to read `## Artefacts` YAML blocks from capability specs and scaffold physical artefacts (files, gitignore entries, directories) with variable substitution and platform variants. Pre-push hook templates added. `adoption-manifest` owner schema gains optional `email` field. `adhere-to` and `adherence-check` gain tooling drift check (`#### Against tooling`).
- **0.1.5** — self-contained commands: `tooling/spec.md` defines when commands must be self-contained (`canonical_spec` + `canonical_spec_version` frontmatter fields); `CONTRIBUTING.md` added for standard developers; `review-optimisations` command promoted to standard.
- **0.1.4** — spec-health suite: `conformance`, `catalogue`, `decision-nudge`, `observability` agents and dashboard promoted to `specs/tooling/spec-health/`. `adherence-check` gains `#### Against tooling` drift check.
- **0.1.3** — agent capability: four-contract pattern (specification, security, implementation, observability) for automated agents running with `--dangerously-skip-permissions` promoted to `specs/tooling/agent/`.
- **0.1.2** — function capability: structural type for cross-cutting business functions (Revenue, Marketing, Finance, etc.) promoted to `specs/function/`.
- **0.1.1** — interface-aware bootstrap: `oos:adopt-manifest` now elicits the adopter's LLM interface and writes the agent-instructions file and command artefacts at that interface's paths (Claude Code, GitHub Copilot, Cursor), and verifies each capability's scaffolding instead of assuming Claude Code conventions.
- **0.1.0** — initial public release.

## Feedback

Adopters are encouraged to share their experience. Open a [GitHub Issue](https://github.com/Busuu/open-org-spec/issues) or email `javier.fdez@gmail.com` with subject `[open-org-spec feedback] <one-line summary>`.

## License

See [LICENSE](./LICENSE).
