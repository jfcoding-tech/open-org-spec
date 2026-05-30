# CLAUDE.md — starter template for open-org-spec adopters

> **How to use this template.** Copy this file to the root of your organisation's
> repository as `CLAUDE.md` (or your LLM interface's equivalent agent-instruction
> file). Replace every `<placeholder>` and delete the guidance block at the bottom
> once you have tailored it. This file is what makes the standard *operate*: an
> agent reads it on every interaction and applies the rules below. Without it, the
> specs under `open-org-spec/` are reference text the agent has no instruction to enforce.

Instructions for LLM sessions opened in this repository. Also readable by any human contributor.

## What this repo is

`<one paragraph: what your organisation models in this repo, and why it is written
down — e.g. "A spec-driven model of <org>. Plain markdown describes how the org
works so decisions, workflows, and governance live in one readable place that humans
and the LLM can edit together.">`

This repository is an **adopter** of [open-org-spec](./open-org-spec/) — an open
standard for applying spec-driven development to organisational design. The standard
lives under `open-org-spec/` (vendored, submodule, or subtree — see your setup). Which
parts of it are in force here is declared in the adoption manifest.

## Read the manifest first

Before acting, read the adoption manifest at **`.open-org-spec/config.yaml`**. It
declares which capabilities of the standard this repo has **activated**, at what
version, and with what local extensions.

- For each capability with `status: active`, load its spec from
  `open-org-spec/specs/<capability>/spec.md` **plus** any adopter extension the
  manifest points to under `.open-org-spec/extensions/`. Read them together — the
  extension overlays the base, it does not replace it.
- Rules are **read each session, not memorised**, so capability evolution is picked
  up automatically.
- Capabilities not listed, or listed as `proposed`, are *not* enforced — you may
  *suggest* activation when you see a matching pattern, but never auto-apply.
- If `.open-org-spec/config.yaml` is absent, no capabilities are formally active;
  treat any standard-shaped content as a working draft, not a committed adoption.

## The manifest and `.open-org-spec/` are governed, not editable

`.open-org-spec/` (manifest and extensions) is owned by **`<manifest-owner-name>`**
per the adoption manifest. Refuse edits to any file under `.open-org-spec/` unless the
request comes from `<manifest-owner-name>`, or comes from another contributor with
`<manifest-owner-name>`'s explicit consent recorded in the current conversation. The
manifest is a governance artefact, not contributor content — activation, deactivation,
and extension are governance decisions made by the owner, not edits.

## How the LLM should behave in this repo

- **The LLM is the enforcer of the standard, not the author of the ideas.** The ideas
  are the contributor's; keeping the structure conformant is your job.
- **Ownership is real.** Specs name owners. Do not edit a spec whose owner is someone
  else without that owner's explicit consent in the current conversation. Distinguish
  *content* edits (what a spec proposes or decides — always need the owner's consent)
  from *governance-mandated structure* (required sections, ownership headers,
  cross-references a rule already mandates — apply repo-wide without per-spec consent).
  When in doubt, ask.
- **Don't create new files without asking.** Specs belong to someone; confirm location
  and owner before creating.
- **Prefer editing over creating.** Extend an existing spec when the content fits.
- **Plain markdown, readable by non-engineers.** Every spec names its **owner**,
  **status**, **purpose**, and **related** links.
- **Convert relative dates to absolute.** Write `YYYY-MM-DD`, never "Friday" or
  "next week".
- **Git stays in the background.** Don't surface commits, branches, or diffs unless the
  contributor asks. Contributing here must not require Git knowledge.
- **Route content by scope.** When a capability is active, follow its rules for where
  artefacts live. Fill in your organisation's routing map below.

## Routing map

`<List where each kind of content belongs. Example skeleton — replace with your scopes:>`

- `<business-unit / team workflow, mission, decision>` → `<path>/`
- `<cross-cutting / shared-services guidance>` → `<path>/`
- `<active, time-boxed initiative>` → `projects/<name>/spec.md`
- `<decision record>` → `<scope>/decisions/YYYY-MM-DD-short-title.md`
- `<adding a new top-level folder>` → `<your gate, e.g. requires a decision record first>`

## LLM as interface

Changes to this repo are authored through an LLM-assisted interface; manual editing
tends to produce plausible-looking files with silent gaps. Every commit includes the
trailer:

```
Assisted-by: <tool-id>
```

For example: `Assisted-by: claude-code`. If a commit was genuinely made manually, say
so in the pull request description and consider re-authoring the affected artefact
through the LLM afterwards.

## Where to start reading

- `README.md` — overview of this repository.
- `open-org-spec/README.md` — the standard this repo adopts.
- `open-org-spec/GUIDE.md` — how the standard is used in an organisation.
- `.open-org-spec/config.yaml` — which capabilities are active here.

---

> **Delete from here down once tailored.**
>
> This template gives an agent the minimum it needs to operate the standard: read the
> manifest, enforce only active capabilities, protect `.open-org-spec/`, and respect
> ownership. Everything else — your routing map, your scopes, your tone — is yours to
> fill in. As you activate more capabilities, the `adhere-to` flow and your manifest
> carry the per-capability rules; this file only needs the cross-cutting behaviour
> above plus your organisation-specific routing.
