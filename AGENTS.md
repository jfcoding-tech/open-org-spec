# AGENTS.md — open-org-spec

Entry point for LLM agents working with this repository. (Human-readable too — start at [`README.md`](./README.md).)

## If you've been asked to set this standard up in an organisation's repo

Read and execute [`specs/adoption-manifest/adopt.md`](./specs/adoption-manifest/adopt.md) — invoked as `oos:adopt-manifest`. It is the **autonomous bootstrap**: in one run it determines the adopter's LLM interface, scaffolds the adoption manifest (`.open-org-spec/config.yaml`), generates the repo's contributor guide from [`templates/CLAUDE.md`](./templates/CLAUDE.md) **at the interface's agent-instructions path**, and activates the capabilities the adopter chooses (scaffolding their content and, where the interface supports them, command artefacts).

It elicits only what it cannot infer — the **LLM interface** (Claude Code, GitHub Copilot, Cursor, …), the manifest owner (a named person), a one-line description of the organisation, and which capabilities to activate first — then proceeds with no manual file editing. **Resolve the interface first**: the guide and command files must go where that interface actually reads them (e.g. `.github/copilot-instructions.md` for Copilot, not `CLAUDE.md`) — see the interface table in [`specs/adoption-manifest/adopt.md`](./specs/adoption-manifest/adopt.md#interface-conventions). Do not hand-scaffold the manifest or guide yourself; run the command, which does it consistently and verifies each capability's scaffolding landed.

## If you're working in a repo that has already adopted this standard

Read the adopter's contributor guide (`CLAUDE.md` or the interface's equivalent) and the manifest at `.open-org-spec/config.yaml` **first**. Enforce only the capabilities marked `active`, loading each capability's spec (`open-org-spec/specs/<capability>/spec.md`) plus any adopter extension the manifest points to. Rules are read each session, not memorised. See [`GUIDE.md`](./GUIDE.md).

## Orientation

open-org-spec is an open standard for applying spec-driven development to organisational design. It is **interface-agnostic** — Claude Code / `.claude/` paths appear only as one worked example of an LLM interface; substitute your own interface's command directory and hook mechanism. The standard's logic lives in the capability and tool specs under [`specs/`](./specs/); adopter-side files (relays, manifest, guide) are thin and scaffolded from [`templates/`](./templates/).
