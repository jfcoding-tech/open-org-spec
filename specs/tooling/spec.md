# Tooling

A capability of open-org-spec describing how tools that operate *against* a conformant repository are governed: what tooling is, where it lives, who owns it, and how a prototype graduates to a standard-level spec.

**Status:** Draft (0.1.0)

## Purpose

A spec-driven repository accumulates tools alongside specs — commands, agents, hooks, and scripts that help contributors orient themselves, ingest content, or maintain the repo. Without a canonical shape, every adopter re-invents the conventions: where tools live, who owns them, how they are versioned, and how they relate to the spec content they operate against.

This capability defines tooling as a first-class governed artefact category so adopters can compose tools deliberately rather than ad hoc.

## Pattern

### What tooling is

**Tooling** is any artefact that *operates against* a conformant repository rather than describing it. A workflow spec describes what a cluster does; a command that helps a contributor orient themselves after a pull is tooling. The distinction is execution: tooling runs; specs describe.

Sub-types named (not fully specified here — each earns its own spec when two or more instances validate the pattern):

- **Commands** — slash commands or equivalent invocations in an LLM interface (e.g. `/catchup`, `/ingest`).
- **Agents** — subagents specialised for a specific task within the repo.
- **Hooks** — shell commands triggered by events (session start, pre-commit, tool call).
- **Skills** — reusable prompt-level patterns invoked by commands or agents.
- **Scripts** — standalone executables operating on the repo outside the LLM interface.

### Where tooling lives

**Standard-side tools** — tools defined by the standard, reusable across any conformant repo — live in `open-org-spec/specs/tooling/<name>/`. Each tool has at minimum a `spec.md`; an `adopt.md` command is added when the adoption flow is well enough understood to scaffold.

**Adopter-side implementations** — the tool as instantiated in a specific repo — live wherever the adopter's LLM interface resolves them. For Claude Code adoptions: `.claude/commands/<name>.md` for commands, `.claude/agents/<name>/` for agents, `.claude/settings.json` for hooks. The standard does not prescribe the exact path; it prescribes that the implementation is co-located with the tooling configuration the interface reads.

**Per-tool adopter extensions.** Tools defined by the standard may be extended per-tool by an adopter without restating the tooling-wide concerns the adopter declares once. Per-tool extensions live at `.open-org-spec/extensions/tooling/<tool>/spec.md` and are declared in the manifest's `tool_extensions` map. See [`../adoption-manifest/spec.md`](../adoption-manifest/spec.md#per-tool-extensions) for the schema and load mechanism.

### Ownership

**Capability-first authorship applies to tooling.** A tool with multiple consumers — any command used by contributors across clusters, any agent invoked from multiple scopes — is governed at infrastructure scope, not within any one consumer's path. In a conformant repo with a cross-cutting infrastructure team, that team owns the tool spec.

A tool created by a single team for their own use may start as a project-local artefact. Once a second consumer adopts it, ownership lifts to infrastructure scope. This mirrors the capability-first principle for spec-level capabilities.

### Lifecycle

1. **Prototype.** A tool is first built as a time-boxed project (`projects/<name>-v0/`). The project validates the pattern — does it solve the problem? does more than one contributor use it? The project has a close criterion; when met, it closes.

2. **Graduation.** A validated prototype graduates to `open-org-spec/specs/tooling/<name>/spec.md`. The project closes with a pointer to the spec. What the project learned — extension points, failure modes, known limitations — flows into the spec.

3. **Adoption.** Adopters instantiate the tool in their repo, typically via an `oos:adopt-<name>` command that scaffolds the implementation. The adopter's implementation extends the spec with org-specific context.

4. **Extension.** The adopter's implementation may add behaviour not in the generic spec. Extensions that prove broadly useful are proposed back to the standard as spec revisions.

### Scope classification

Every command in an adopter's tooling directory is either **repo-wide** or **scoped**.

- **Repo-wide** — the command serves all contributors regardless of which cluster, module, or project they work in. Owned at the infrastructure team or repo-wide governance level. Lives directly in the adopter's command directory (e.g. `.claude/commands/<name>.md`) and is its own canonical definition.

- **Scoped** — the command serves one specific cluster, module, or project. It is owned by that scope's lead, not the infrastructure team. Its canonical definition lives in the scope, not in the command directory.

Scope ownership determines who may change the command. A scoped command's content, behaviour, and extension points are the owning scope's decision. The infrastructure team governs the command directory's structure and the relay convention, not the commands themselves.

### Canonical spec location for scoped commands

A scoped command's full definition — what it does, how it behaves, what it reads — lives at `<scope>/tools/<name>.md` within the owning scope. The `tools/` folder is the governed home for scope-local tooling specs. It sits at the scope root alongside `README.md`, `people.md`, and `decisions/`.

The command directory entry for a scoped command is a **thin relay** — it names the owning scope and tells the agent to read and execute the canonical spec:

```markdown
---
description: <one-line description>
owner: <scope path>
---

# /<command-name>

This command is owned by `<scope>`. Read [`<scope>/tools/<name>.md`](<relative-path>) and execute it.
```

This keeps the command invocable from the adopter's LLM interface while moving ownership, maintenance, and extension to where the knowledge lives.

**Representation is extension-overridable.** The relay shape shown above (markdown frontmatter + body line) is the default. Adopters may declare a different relay form in their extension spec (different frontmatter keys, different body wording, an alternate file shape for non-Claude-Code interfaces), provided the relay remains readable by the adopter's LLM interface, the canonical-spec link is preserved, and the extension declares the mapping. The capability requires the relay's behaviour (read and execute the canonical spec) and the discoverability link, not the syntactic form. Removing the canonical-spec link, breaking interface-readability, or making relays unable to be uniformly listed in the commands README is not authorised by this override — only the form changes; the contract does not.

### Commands governance directory

The adopter's command directory carries a `README.md` — the ownership index. It lists every command, its classification (repo-wide or scoped), its owner, and a link to its canonical spec or relay target. This is the single surface a contributor reads to understand who owns a command and how to change it.

The README is owned by the infrastructure team for repo-wide commands, and by each scope's lead for scoped commands listed there.

### Shared primitives

Tools within one adopter's repo frequently share logic: role detection, repo-state inspection, feedback-inbox scanning. A shared primitive used by two or more tools lifts to its own named layer (a shared skill or utility spec) rather than duplicating across tool implementations. The standard names this rule; the adopter owns the shared layer.

### Tool stamping (state-changing tools)

A tool that writes to a file declares stamping behaviour in its spec. Stamping records first-use of the tool on the file via a `tooling` block in the file's frontmatter (or the equivalent location declared by the host capability — for `project` specs, see [`../project/spec.md#tooling-stamps`](../project/spec.md#tooling-stamps)).

Stamping enables adoption measurement. *"Which files have been touched by tool X?"* becomes a grep query, not a telemetry question. The metadata lives next to the artifact it describes.

**Two kinds of tools, two stamping behaviours.**

- **State-changing tools** — those that write to files (e.g., `oos:new project` on scaffold, `oos:adhere-to` in `fix-with-me` mode, adopter-extension tools that modify governed artefacts). Stamping is required: the tool's write must include the stamp update.
- **Read-only tools** — those that report or surface but do not modify (e.g., `oos:catchup`). Stamping is not applicable; their adoption is measured by a separate mechanism (not specified in this capability at v0).

**Authority.** The stamp is part of the tool's atomic write. A tool that modifies a file but does not stamp emits a `warning` finding from [`../adherence-check/spec.md`](../adherence-check/spec.md). The stamp is therefore not optional for state-changing tools — it is part of conformance.

**First-use plus last-use.** The conventional stamp records `first` (date of first invocation against the file), optionally `last` (date of most recent invocation, omitted when equal to first), and `by` (most recent invoker). Per-file invocation counts are not tracked; aggregate counts are answered by grep across the repo, not by per-file state.

## What is not prescribed

- **The specific LLM interface or deployment mechanism.** Commands are described generically; the `.claude/commands/` path is the Claude Code convention, not a standard requirement.
- **A complete spec for each sub-type.** Commands, agents, hooks, skills, and scripts share the category and governance rules. Each sub-type earns its own capability spec when instances accumulate.
- **Whether every scope has tools.** Absence is valid. Most scopes are served entirely by higher-scope tools.

## Rationale

Tooling accumulated in the standard's reference implementation — four commands under one parent thesis — before any canonical location or governance rule existed. Each was authored as an ad-hoc project; the post-v0 fate of each was unspecified; shared primitives (role detection, feedback scanning) were re-derived independently. The first graduating tool (`catchup`) validated the shape; the category is now ready to be first-class.

## Adoption

*(An `oos:adopt-<name>` pattern for scaffolding tool implementations is deferred pending a second adopter instance. Until then, apply the pattern manually: implement the tool at the path your LLM interface resolves, follow the tool's `spec.md` for behaviour, extend with org-specific context in the implementation file.)*

## Related

- [`catchup/spec.md`](./catchup/spec.md) — reference implementation: the first tool to graduate to this spec.
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — companion capability used by tools that scan contributor inboxes.
- [`../people/spec.md`](../people/spec.md) — tools that detect contributor roles depend on the people-at-scope shape.
- [`../../backlog.md`](../../backlog.md) — "Adopter-side tooling as a governed artefact category" (added 2026-05-05). This spec is its graduation.
