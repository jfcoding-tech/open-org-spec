# Extend a capability or tool (command)

Invoked as: `oos:extend <capability>` (extends a capability) or `oos:extend <capability>/<tool>` (extends a specific tool within a capability).
Part of: [`adoption-manifest`](./spec.md) capability.

## Purpose

Scaffold an extension spec — for a capability declared in the adopter's manifest, or for a specific tool within a capability. The extension declares what the adopter adds to the base spec (additional required fields, additional sections, refined rules). The command creates the shape; the adopter fills in the content.

Extensions are how adopters customise the standard without modifying it — the base spec and the extension are read together by agents to form the effective rules in this repo. Capability extensions cover capability-wide concerns; tool extensions cover behaviour specific to one tool within a capability. The two compose: an adopter may extend a capability AND extend specific tools within it (see [`spec.md`](./spec.md#per-tool-extensions)).

## Preconditions

- A manifest exists at `.open-org-spec/config.yaml` (run `oos:adopt-manifest` first if not).
- The named `<capability>` is declared in the manifest with status `active` or `proposed`. Extending an `inactive` or unlisted capability (or a tool within one) is refused — there is nothing to extend.
- For tool-extension mode: the named `<tool>` exists as a folder under `open-org-spec/specs/<capability>/`. Refused if not.
- No extension already exists at the target path. For capability mode: `.open-org-spec/extensions/<capability>/spec.md` does not exist. For tool mode: `.open-org-spec/extensions/<capability>/<tool>/spec.md` does not exist. If one does, the command refuses; edits to an existing extension go through the manifest owner's consent on the existing file. A capability extension and tool extensions for the same capability are independent targets — having one does not preclude scaffolding the others.
- The contributor running the command is the manifest owner, or has the manifest owner's explicit consent recorded in the current conversation. Extensions are governance artefacts under the manifest's ownership.

## Inputs (elicited from the adopter)

1. **Target.** Either a capability slug (e.g. `tooling`) or a `<capability>/<tool>` path (e.g. `tooling/catchup`). The command parses the input, validates that the slug or path resolves to a real capability or tool, and sets the mode (capability vs tool) accordingly.
2. **Extension owner.** Defaults to the manifest owner. May be a different named person if the adopter wants to delegate stewardship of this specific extension (e.g., the cluster lead owns their cluster's extension). The owner appears in the scaffolded extension's header.
3. **(Optional) Brief purpose statement.** A one-sentence description of why this extension exists, used to populate the `Purpose` section's first line. The adopter can refine afterwards.

## Outputs

One file scaffolded, one manifest field updated. The exact target depends on the mode.

**Capability mode** (`oos:extend <capability>`):
- **`.open-org-spec/extensions/<capability>/spec.md`** — the extension spec, scaffolded with the canonical structure (Status, Extends, Owner, Declared in, Purpose, What this extension adds, What this extension does not change, Conformance notes, Rationale, Related). Section headings are present; section bodies carry guidance comments for the adopter to replace with actual content.
- **`.open-org-spec/config.yaml`** — the `<capability>` entry gains an `extension: extensions/<capability>/spec.md` field. The manifest owner's consent in step 5 below covers this edit.

**Tool mode** (`oos:extend <capability>/<tool>`):
- **`.open-org-spec/extensions/<capability>/<tool>/spec.md`** — the tool extension spec, scaffolded with the same canonical structure. `Extends:` points at the tool's base spec under `open-org-spec/specs/<capability>/<tool>/spec.md`.
- **`.open-org-spec/config.yaml`** — the `<capability>` entry's `tool_extensions` map gains an entry: `<tool>: extensions/<capability>/<tool>/spec.md`. The map is created if it does not exist. The capability-level `extension:` field is left untouched.

## Steps

1. **Verify manifest.** Check that `.open-org-spec/config.yaml` exists. Refuse if not.
2. **Parse target and set mode.** Read the input. If it contains `/`, treat as tool mode (`<capability>/<tool>`); otherwise capability mode.
3. **Verify target is declared and extensible.** Read the manifest. Refuse if `<capability>` is not listed, or if its status is `inactive`. Allow `active` or `proposed`. For tool mode, also verify that `open-org-spec/specs/<capability>/<tool>/` exists in the standard; refuse if not.
4. **Verify no existing extension at the target.** For capability mode: refuse if `.open-org-spec/extensions/<capability>/spec.md` exists. For tool mode: refuse if `.open-org-spec/extensions/<capability>/<tool>/spec.md` exists. A capability extension and tool extensions for the same capability are independent — having one does not block scaffolding the others.
5. **Elicit extension owner and brief purpose.** If the caller is not the manifest owner, also elicit the owner's consent before proceeding.
6. **Verify owner consent.** If the caller is the manifest owner, proceed. Otherwise, surface the requested change to the manifest owner for explicit approval in the conversation. Do not proceed without their response.
7. **Scaffold the extension.** Create the target file (capability mode: `.open-org-spec/extensions/<capability>/spec.md`; tool mode: `.open-org-spec/extensions/<capability>/<tool>/spec.md`) populated with:
   - Title: `# <Capability>` (capability mode) or `# <Capability>/<Tool>` (tool mode) `— <adopter-slug> extension`
   - `Status: Active (extension)` (capability mode) or `Status: Active (tool extension)` (tool mode)
   - `Extends: <relative path to the base capability or tool spec>`
   - `Owner: <extension owner from input 2>`
   - `Declared in: <relative path to config.yaml>`
   - `Purpose` section with the brief purpose statement (or a placeholder if none provided)
   - Empty `What this extension adds` section with guidance comments
   - Empty `What this extension does not change` section with guidance comments
   - Empty `Conformance notes` section
   - Empty `Rationale` section
   - `Related` section pre-populated with links to the base spec, the adoption-manifest spec, and the manifest file
8. **Update the manifest.** Capability mode: add `extension: extensions/<capability>/spec.md` to the `<capability>` entry. Tool mode: add an entry to the `<capability>` entry's `tool_extensions` map (creating the map if needed): `<tool>: extensions/<capability>/<tool>/spec.md`. Preserve all other fields.
9. **Surface to the adopter.** Show the scaffolded file. Remind the adopter that the extension is empty — agents will read it as authoritative once committed, so contributors should fill in the actual additions before relying on it. Recommend running `oos:adhere-to <capability>` after the extension is filled in, to surface conformance gaps the new rules introduce.

## Refusal conditions

- **No manifest exists.** Redirect to `oos:adopt-manifest`.
- **Capability not declared in manifest.** Redirect to `oos:adopt-<capability>` (per-capability activation, which adds the entry to the manifest).
- **Capability status is `inactive`.** Extending a deliberately-not-adopted capability (or a tool within one) is incoherent. The adopter must reactivate first.
- **Tool does not exist in the standard.** Refuse if `<tool>` is named but `open-org-spec/specs/<capability>/<tool>/` is not present.
- **Extension already exists at the target.** The command does not overwrite existing extensions. The adopter edits the existing file directly (with manifest owner's consent, since the extension is owned). Per-target check: an existing capability extension does not block scaffolding a tool extension and vice versa.
- **Caller is not the manifest owner and consent is not recorded.** Refuse and ask the caller to obtain explicit consent from the manifest owner before proceeding.
- **No extension owner can be determined.** Refuse — every extension must name an owner, defaulting to the manifest owner.

## Non-goals

- **Does not infer the extension's content.** What the adopter adds to the base capability or tool is the adopter's decision; the command scaffolds the shape, not the additions. The adopter writes the rules; the command does not generate them from observed repo patterns.
- **Does not run `adhere-to` afterwards.** Extensions may introduce new conformance rules; adhere-to is a separate step the adopter runs when ready.
- **Does not retire or replace existing scaffolding outside `.open-org-spec/`.** If the adopter previously used a template or convention to capture what is now in an extension, retiring the older artefact is a separate decision — handled via the adopter's own feedback or governance flow, not by this command.
- **Does not extend below tool granularity.** Capability extensions and per-tool extensions are the two supported levels. Sub-tool extensions (e.g., extending one step of a tool) are not in scope; an adopter wanting that granularity restructures via the full tool extension.

## Examples

*(To be added: a worked conversation showing extension scaffolding for the `project` capability, with the manifest update applied.)*
