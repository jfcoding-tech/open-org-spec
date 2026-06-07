# Adopt manifest (command)

Invoked as: `oos:adopt-manifest`
Part of: [`adoption-manifest`](./spec.md) capability.

## Purpose

Bootstrap a repository into a working, enforced open-org-spec adoption **in a single run, with no manual file editing**, on **whichever LLM interface the adopter uses**. The command:

1. determines the adopter's LLM interface and the file conventions that follow from it;
2. scaffolds the `.open-org-spec/config.yaml` manifest (owner + pinned standard version);
3. generates the adopter's contributor guide from [`templates/CLAUDE.md`](../../templates/CLAUDE.md), **written to the interface's agent-instructions path** (e.g. `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot), with owner, org description, and routing skeleton filled in;
4. activates the capabilities the adopter chooses — for each, scaffolding its content (e.g. a `governance/` folder) and, **where the interface supports invocable commands**, wiring command artefacts; then verifying each completed before moving on.

This is the entry point an adopter — or an LLM acting for one — runs first. The only human input is a short interactive Q&A for what the command cannot infer: the LLM interface, the manifest owner, a one-line org description, and which capabilities to activate. Everything else is scaffolded.

> **The standard is interface-agnostic; the adopter's repo is not.** This command's job is to resolve the standard's interface-neutral conventions to the *concrete* files the adopter's interface actually reads. Skipping this (and defaulting to one interface's paths) produces files the adopter's tool ignores — e.g. a `CLAUDE.md` that GitHub Copilot never loads.

## Interface conventions

The command resolves three things from the adopter's interface: the **agent-instructions file** (the always-loaded guide), the **command mechanism** (how invocable commands are registered, if at all), and the **session-start hook** (auto-run-on-open, if any). Known mappings:

| Interface | Agent-instructions file | Invocable commands | Session-start hook |
|-----------|------------------------|--------------------|--------------------|
| **Claude Code** | `CLAUDE.md` (repo root) | `.claude/commands/<name>.md` relay files | `.claude/settings.json` `SessionStart` |
| **GitHub Copilot** | `.github/copilot-instructions.md` (repo-wide; `AGENTS.md` is also read by the Copilot coding agent) | `.github/prompts/<name>.prompt.md` prompt files (invoked as `/<name>` in chat) | none — commands are invoked manually |
| **Cursor** | `.cursor/rules/*.mdc` (or legacy `.cursorrules`) | no native relay mechanism — register commands as rules or invoke by pointing at the spec | none |
| **Other / unknown** | **ask the adopter** | **ask** whether the interface supports invocable commands, and where | **ask** whether a session-start hook exists |

For an unlisted interface, the command asks the adopter for these three facts rather than guessing. When an interface has **no command mechanism**, commands are still usable — the adopter (or agent) invokes them by reading the canonical spec; the commands README records this instead of listing relay files.

## Preconditions

- The adopter's repository exists and the contributor has write access.
- The open-org-spec standard is available — co-located in the repo (e.g. `open-org-spec/` folder, submodule, or clone), or referenced by version identifier.
- `.open-org-spec/config.yaml` does not already exist at the adopter's repo root. (If it does, the command refuses; see "Refusal conditions".)

## Inputs (elicited interactively)

The command asks for these during the run, then proceeds without further manual steps:

1. **LLM interface.** Which interface the team uses (Claude Code, GitHub Copilot, Cursor, or other). Resolves to the conventions in the table above. For "other", the command elicits the agent-instructions path, command mechanism, and hook availability.

2. **Owner.** Name + organisational role of the person accountable for the manifest — the only one authorised to activate, deactivate, or extend capabilities without explicit consent. If the adopter names a generic role ("the team"), the command explains and re-asks. Ownership is by name.

3. **Standard version.** The open-org-spec version to pin to. Defaults to the latest detected when the standard is co-located; the adopter may override.

4. **Organisation description.** One or two lines answering "what does this repo model?" — used to fill the contributor guide's opening. The command also proposes a minimal **routing-map skeleton** (where each kind of content lives) and confirms it.

5. **Capabilities to activate now.** The command lists the available capabilities (read from `open-org-spec/specs/`) with a one-line summary each; the adopter picks zero or more. The command **recommends starting with one or two** that match a real, current use case — activating everything at once is against the standard's incremental, fog-of-war posture and lengthens the run, raising the chance a step is dropped.

6. **(Optional) Capabilities to record as `proposed`.** Any the adopter wants to note for later evaluation without activating.

## Outputs

- **`.open-org-spec/config.yaml`** — manifest with the declared `owner`, `standard_version`, chosen capabilities marked `active` (with today's `activated` date), and any `proposed` entries.
- **`.open-org-spec/extensions/`** — directory for capability extensions; created empty, populated if an activated capability needs one.
- **The contributor guide at the interface's agent-instructions path** — generated from `templates/CLAUDE.md` with the org description, manifest owner (in the `.open-org-spec/` protection rule), and routing map filled in. Path per the interface table (e.g. `.github/copilot-instructions.md` for Copilot), **not** a hardcoded `CLAUDE.md`.
- **Per activated capability:** its scaffolded content (e.g. `governance/README.md` + `decisions/` for `governance-at-scope`), plus — where the interface supports invocable commands — command artefacts (relay or prompt files) and rows in the commands README. For interfaces without a command mechanism, the commands README records invoke-by-spec-reference instead.

## Steps

1. **Check preconditions.** Verify `.open-org-spec/config.yaml` does not exist (refuse if it does) and that the contributor has write access.

2. **Detect standard location.** Look for open-org-spec co-located, as a submodule, or by version identifier. If none is found, ask the adopter to point at it.

3. **Determine the LLM interface.** Ask the adopter (or detect from existing markers — `.claude/`, `.github/copilot-instructions.md`, `.cursor/`). Resolve the agent-instructions path, command mechanism, and hook availability from the interface table. For an unlisted interface, elicit the three facts.

4. **Elicit owner.** Collect name + role; apply the named-person rule and re-ask on a generic answer.

5. **Confirm standard version.** Default to the latest detected; allow override.

6. **Elicit org description + routing map.** Collect the one-line description. Propose a routing-map skeleton and confirm it.

7. **Present capabilities and elicit choices.** Read `open-org-spec/specs/` and list each capability with a one-line summary. Recommend starting small; record the chosen `active` set and any `proposed`.

8. **Scaffold the manifest.** Write `.open-org-spec/config.yaml` with:
   - `standard_version` — the version confirmed in step 5.
   - `adoption_mechanism` — ask the adopter: "Does the standard arrive as a git submodule or as a zip file?" Record `submodule` or `zip`. No default.
   - `incoming_path` — if `adoption_mechanism: zip`, ask: "Where will you place zip archives before running `/bump`? (e.g. `.open-org-spec/incoming/`)" Record the path.
   - `contributor_guide` — the agent-instructions path resolved in step 3 (e.g. `CLAUDE.md`, `.github/copilot-instructions.md`). Always set; the `tooling` capability's `adhere-to` check depends on it.
   - `owner` — name, role, and email from step 4.
   - Capability entries — chosen capabilities marked `active` (dated today), and any `proposed` entries.
   Create `.open-org-spec/extensions/`.

9. **Generate the contributor guide at the interface's path.** Write the agent-instructions file in two parts:

   **Part A — governed section.** Read `open-org-spec/templates/contributor-guide.md`. Replace `<manifest-owner-name>` with the manifest owner's name (step 4). Wrap in sentinels:

   ```
   <!-- oos:governed-start v<standard_version> -->
   <governed content>
   <!-- oos:governed-end -->
   ```

   **Part B — adopter section.** Append the adopter-specific skeleton below the closing sentinel: the "What this repo is" paragraph (org description from step 6), the routing map (step 6), and the "Where to start reading" section from `templates/CLAUDE.md`. The adopter customises this section; the governed section above it is managed by `/bump`.

   Write the combined file to the agent-instructions path resolved in step 3.

   **If a guide already exists at that path, do not overwrite it** — surface the governed section (Part A) for the owner to merge above their existing content (see "Refusal conditions").

10. **Activate the chosen capabilities — one at a time, verifying each.** For each capability selected in step 7:
    - If it ships a dedicated `oos:adopt-<capability>` command (e.g. `governance-at-scope`), execute that; otherwise set its status to `active` and run `adhere-to <capability>`.
    - Where the interface supports invocable commands (step 3), wire the capability's command artefacts (relay or prompt files) and add rows to the commands README; where it does not, record invoke-by-spec-reference in the README instead.
    - **Verify the capability's scaffolding actually landed** before moving to the next — e.g. `governance-at-scope` must have produced `governance/README.md` and a `decisions/` folder; activation must have created or updated the commands README. If a step did not complete (a common failure on less-agentic interfaces), retry it or report it explicitly — never silently move on.
    Activation surfaces gaps; it does not unilaterally rewrite owners' content.

11. **Suggest protection layers.** For PR-based workflows, recommend a CODEOWNERS rule for `.open-org-spec/` naming the owner. For direct-push workflows, the agent-level rule is already in the generated guide; note that Git-level options are tracked in `backlog.md`.

12. **Confirm.** Display the interface resolved, the created manifest, the guide (and its path), the capabilities activated **with their scaffolding verified**, the command artefacts (or the invoke-by-reference note), and any gaps surfaced. The repo is now an enforced adoption.

## Refusal conditions

- **Manifest already exists.** The command does not overwrite or update an existing manifest. The adopter is redirected to per-capability adopt commands (which update the manifest) or to manual edits with owner consent.
- **No owner provided, or generic owner.** No manifest is scaffolded without a named accountable person. "TBD" or "the team" are not accepted.
- **Standard cannot be located.** If open-org-spec is neither co-located, a submodule, nor referenceable by version, the command refuses and asks the adopter to set up the standard reference first.
- **Contributor guide already exists at the interface's path.** The command does not overwrite an existing agent-instructions file. It still scaffolds the manifest and surfaces the guide additions (protection rule + standard-orientation lines) for the owner to merge.

## Non-goals

- **Does not invent the organisation's content.** It scaffolds the adoption surface (manifest, guide, capability content, command artefacts); the org's actual specs, rosters, and decisions are authored later through the LLM interface.
- **Does not infer adoption from existing repo state.** Even if the repo already has `people.md` files or `governance/` folders, capabilities are activated only when the adopter chooses them in step 7 — never auto-detected from convention.
- **Does not fabricate a command mechanism where the interface has none.** It records invoke-by-spec-reference rather than inventing relay files the interface would ignore.
- **Does not apply Git-level protection (CODEOWNERS or branch rules).** Those are recommended in step 11 but applied by the adopter.

## Examples

*(To be added: worked bootstraps on two interfaces — Claude Code, GitHub Copilot — showing how the agent-instructions path and command artefacts differ while the manifest and capability scaffolding stay identical.)*
