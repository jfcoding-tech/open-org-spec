# AGENTS.md — open-org-spec

Entry point for LLM agents working with this repository. (Human-readable too — start at [`README.md`](./README.md).)

## If you've been asked to set this standard up in an organisation's repo

Read and execute [`specs/adoption-manifest/adopt.md`](./specs/adoption-manifest/adopt.md) — invoked as `oos:adopt-manifest`. It is the **autonomous bootstrap**: in one run it scaffolds the adoption manifest (`.open-org-spec/config.yaml`), generates the repo's contributor guide from [`templates/CLAUDE.md`](./templates/CLAUDE.md) with the owner filled in, and activates the capabilities the adopter chooses (running `adhere-to` for each to wire command relays and surface gaps).

It elicits only what it cannot infer — the manifest owner (a named person), a one-line description of the organisation, and which capabilities to activate first — then proceeds with no manual file editing. Do not hand-scaffold the manifest or guide yourself; run the command, which does it consistently.

## If you're working in a repo that has already adopted this standard

Read the adopter's contributor guide (`CLAUDE.md` or the interface's equivalent) and the manifest at `.open-org-spec/config.yaml` **first**. Enforce only the capabilities marked `active`, loading each capability's spec (`open-org-spec/specs/<capability>/spec.md`) plus any adopter extension the manifest points to. Rules are read each session, not memorised. See [`GUIDE.md`](./GUIDE.md).

## Orientation

open-org-spec is an open standard for applying spec-driven development to organisational design. It is **interface-agnostic** — Claude Code / `.claude/` paths appear only as one worked example of an LLM interface; substitute your own interface's command directory and hook mechanism. The standard's logic lives in the capability and tool specs under [`specs/`](./specs/); adopter-side files (relays, manifest, guide) are thin and scaffolded from [`templates/`](./templates/).
