# Adopt manifest (command)

Invoked as: `oos:adopt-manifest`
Part of: [`adoption-manifest`](./spec.md) capability.

## Purpose

Bootstrap a repository into a working, enforced open-org-spec adoption **in a single run, with no manual file editing**. The command:

1. scaffolds the `.open-org-spec/config.yaml` manifest (owner + pinned standard version);
2. generates the adopter's contributor guide (`CLAUDE.md` or the interface's equivalent) from [`templates/CLAUDE.md`](../../templates/CLAUDE.md), with the manifest owner, a one-line org description, and a routing skeleton filled in;
3. activates the capabilities the adopter chooses — for each, writing its status, scaffolding any extension, and running `adhere-to` to wire command relays and surface gaps.

This is the entry point an adopter — or an LLM acting for one — runs first. It is designed to take an empty or near-empty repository to an enforced adoption autonomously. The only human input is a short interactive Q&A for the things the command genuinely cannot infer: the manifest owner, a one-line description of the organisation, and which capabilities to activate first. Everything else is scaffolded.

## Preconditions

- The adopter's repository exists and the contributor has write access.
- The open-org-spec standard is available — co-located in the repo (e.g. `open-org-spec/` folder, submodule, or clone), or referenced by version identifier.
- `.open-org-spec/config.yaml` does not already exist at the adopter's repo root. (If it does, the command refuses; see "Refusal conditions".)

## Inputs (elicited interactively)

The command asks for these during the run, then proceeds without further manual steps:

1. **Owner.** Name + organisational role of the person accountable for the manifest — the only one authorised to activate, deactivate, or extend capabilities without explicit consent. If the adopter names a generic role ("the team"), the command explains and re-asks. Ownership is by name.

2. **Standard version.** The open-org-spec version to pin to. Defaults to the latest detected when the standard is co-located; the adopter may override.

3. **Organisation description.** One or two lines answering "what does this repo model?" — used to fill the contributor guide's opening. The command also proposes a minimal **routing-map skeleton** (where each kind of content lives) for the guide and confirms it with the adopter.

4. **Capabilities to activate now.** The command lists the available capabilities (read from `open-org-spec/specs/`) with a one-line summary each; the adopter picks zero or more. Each chosen capability is activated in this same run.

5. **(Optional) Capabilities to record as `proposed`.** Any the adopter wants to note for later evaluation without activating.

## Outputs

- **`.open-org-spec/config.yaml`** — manifest with the declared `owner`, `standard_version`, chosen capabilities marked `active` (with today's `activated` date), and any `proposed` entries.
- **`.open-org-spec/extensions/`** — directory for capability extensions; created empty, populated if an activated capability needs one.
- **Contributor guide at the repo root** (`CLAUDE.md` or the interface's agent-instruction file) — generated from `templates/CLAUDE.md` with the org description, manifest owner (in the `.open-org-spec/` protection rule), and routing map filled in.
- **Per activated capability:** command relays wired into the adopter's command directory, rows added to the commands README, and any conformance gaps surfaced to their owners (via `adhere-to`).

## Steps

1. **Check preconditions.** Verify `.open-org-spec/config.yaml` does not exist (refuse if it does) and that the contributor has write access.

2. **Detect standard location.** Look for open-org-spec co-located, as a submodule, or by version identifier. If none is found, ask the adopter to point at it.

3. **Elicit owner.** Collect name + role; apply the named-person rule and re-ask on a generic answer.

4. **Confirm standard version.** Default to the latest detected; allow override.

5. **Elicit org description + routing map.** Collect the one-line description. Propose a routing-map skeleton and confirm it. These fill the contributor guide.

6. **Present capabilities and elicit choices.** Read `open-org-spec/specs/` and list each capability with a one-line summary. Ask which to activate now, and which (if any) to record as `proposed`.

7. **Scaffold the manifest.** Write `.open-org-spec/config.yaml` with owner, standard version, the chosen capabilities (`active`, dated today), and any `proposed` entries. Create `.open-org-spec/extensions/`.

8. **Generate the contributor guide.** Copy `open-org-spec/templates/CLAUDE.md` to the repo root as `CLAUDE.md` (or the interface's equivalent). Fill: the org description and routing map (step 5), and the manifest owner's name into the `.open-org-spec/` protection rule (step 3). At bootstrap the guide does not yet exist and the manifest owner being elicited *is* its owner, so the command authors it directly — this is the one moment the standard writes the guide unprompted. **If a guide already exists, do not overwrite it** — surface the protection-rule text and the standard-orientation lines for the owner to merge instead (see "Refusal conditions").

9. **Activate the chosen capabilities.** For each capability selected in step 6: if it ships a dedicated `oos:adopt-<capability>` command (e.g. `governance-at-scope`), invoke that. Otherwise set its status to `active` in the manifest and run `adhere-to <capability>`, which scaffolds the capability's relays, updates the commands README, and routes any gaps to their owners. Activation surfaces gaps; it does not unilaterally rewrite owners' content.

10. **Suggest protection layers.** For PR-based workflows, recommend a CODEOWNERS rule for `.open-org-spec/` naming the owner. For direct-push workflows, the agent-level rule is already in the generated guide; note that Git-level options are tracked in `backlog.md`.

11. **Confirm.** Display the created manifest, the generated guide, the wired commands, and any gaps surfaced. The repo is now an enforced adoption — subsequent capability activations write into the manifest this command created.

## Refusal conditions

- **Manifest already exists.** The command does not overwrite or update an existing manifest. The adopter is redirected to per-capability adopt commands (which update the manifest) or to manual edits with owner consent.
- **No owner provided, or generic owner.** No manifest is scaffolded without a named accountable person. "TBD" or "the team" are not accepted.
- **Standard cannot be located.** If open-org-spec is neither co-located, a submodule, nor referenceable by version, the command refuses and asks the adopter to set up the standard reference first.
- **Contributor guide already exists.** The command does not overwrite an existing `CLAUDE.md` (or equivalent). It still scaffolds the manifest and surfaces the guide additions (protection rule + standard-orientation lines) for the owner to merge, rather than authoring the guide.

## Non-goals

- **Does not invent the organisation's content.** It scaffolds the adoption surface (manifest, guide, relays); the org's actual specs, rosters, and decisions are authored later through the LLM interface.
- **Does not infer adoption from existing repo state.** Even if the repo already has `people.md` files or `governance/` folders, capabilities are activated only when the adopter chooses them in step 6 — never auto-detected from convention.
- **Does not apply Git-level protection (CODEOWNERS or branch rules).** Those are recommended in step 10 but applied by the adopter.

## Examples

*(To be added: a worked conversation showing the full bootstrap of an empty repo — owner elicitation, capability selection, manifest + guide generation, and first-capability activation — end to end.)*
