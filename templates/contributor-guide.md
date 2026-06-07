# Contributor guide — governed section

This file is the **governed content** that the `bump` command splices between the
`<!-- oos:governed-start -->` / `<!-- oos:governed-end -->` sentinels in an adopter's
contributor guide. It is LLM-agnostic — the same text appears whether the adopter
uses `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, or any other
interface file. Replace `<manifest-owner-name>` when the governed section is written
to the adopter's file (the `bump` command does this automatically).

---

## Read the manifest first

Before acting, read the adoption manifest at **`.open-org-spec/config.yaml`**. It
declares which capabilities of the standard this repo has **activated**, at what
version, and with what local extensions.

- For each capability with `status: active`, load its spec from
  `open-org-spec/specs/<capability>/spec.md` **plus** any adopter extension the
  manifest points to under `.open-org-spec/extensions/`. Read them together — the
  extension overlays the base, it does not replace it.
- Rules are **read each session, not memorised** — load them fresh so capability
  evolution is picked up automatically.
- Capabilities not listed, or listed as `proposed`, are not enforced — you may
  *suggest* activation when you see a matching pattern, but never auto-apply.
- If `.open-org-spec/config.yaml` is absent, no capabilities are formally active;
  treat any standard-shaped content as a working draft.

## The manifest and `.open-org-spec/` are governed, not editable

`.open-org-spec/` (manifest and extensions) is owned by **`<manifest-owner-name>`**
per the adoption manifest. Refuse edits to any file under `.open-org-spec/` unless
the request comes from `<manifest-owner-name>`, or comes from another contributor
with `<manifest-owner-name>`'s explicit consent recorded in the current conversation.
The manifest is a governance artefact — activation, deactivation, and extension are
decisions made by the owner, not edits.

## How the agent should behave in this repo

- **The agent is the enforcer of the standard, not the author of the ideas.** The
  ideas are the contributor's; keeping the structure conformant is the agent's job.
- **Ownership is real.** Specs name owners. Do not edit a spec whose owner is someone
  else without that owner's explicit consent in the current conversation. Distinguish
  *content* edits (what a spec proposes or decides — always need consent) from
  *governance-mandated structure* (required sections, ownership headers, cross-
  references a rule already mandates — apply repo-wide without per-spec consent).
  When in doubt, ask.
- **Don't create new files without asking.** Specs belong to someone; confirm
  location and owner before creating.
- **Prefer editing over creating.** Extend an existing spec when the content fits.
- **Plain markdown, readable by non-engineers.** Every spec names its **owner**,
  **status**, **purpose**, and **related** links.
- **Convert relative dates to absolute.** Write `YYYY-MM-DD`, never "Friday" or
  "next week".
- **Git stays in the background.** Don't surface commits, branches, or diffs unless
  the contributor asks.

## When a contribution needs an extension decision

When a contributor proposes something that base specs and current extensions do not
cover, **do not implement**. File a `[gap]` entry to the manifest owner's feedback
inbox and stop. The manifest owner decides whether to extend the relevant capability,
decline with rationale, or proceed without extension.

This applies specifically to:
- Writes to `open-org-spec/` (the standard directory in this repo)
- Writes to `.open-org-spec/extensions/<file>` where the file's declared owner is
  not the current contributor
- Edits to capability entries in `.open-org-spec/config.yaml`

Ordinary spec creation in content areas (`clusters/`, `projects/`, `ai-factory/`, or
equivalent) does not require routing — that is standard contribution, not extension.
