# Adopt governance (command)

Invoked as: `oos:adopt-governance`
Part of: [`governance-at-scope`](./spec.md) capability.

## Purpose

Guide an adopter through setting up a governance folder at a chosen scope in a conformant repository. Produces two files conforming to [`spec.md`](./spec.md): a `governance/README.md` with structured frontmatter and prose body, and a sibling `decisions/README.md` with the ADR convention.

## Preconditions

- The adopter's repository is conformant with open-org-spec, or is in the process of adopting conformance.
- The scope the adopter wants to govern already exists in the repository (the command does not create scopes, only governance folders for existing scopes).
- Adopter has read access to higher-scope governance files if any exist, so they can be cross-referenced.

## Inputs (elicited from the adopter)

1. **Scope.** One of: repo-wide, a specific module path, a cross-module workstream, a project. The command asks; it does not infer.
2. **Owner.** Name + role of the person accountable for how this scope operates. The command validates: if the adopter names a stakeholder (a consumer of the governed function rather than its accountable party), the command refuses and re-asks.
3. **DACI participants.** Name + role for Driver, Approver, Contributors, Informed. Defaults apply if unspecified: Driver = Approver = Owner; Contributors and Informed default to empty.
4. **Cross-references.** Paths to higher-scope governance folders to reference, if any exist. For repo-wide scope, typically none apply.

## Outputs

Two files at the governed scope:

- **`<scope>/governance/README.md`** — YAML frontmatter + prose body, conformant with the schema declared in [`spec.md`](./spec.md#shape-of-a-governance-file).
- **`<scope>/decisions/README.md`** — prose-only, describes the ADR convention at this scope; declares inheritance of DACI from the sibling governance folder.

For repo-wide scope, the two folders appear at the repo root: `/governance/` and `/decisions/`.

## Steps

1. **Identify scope.** Ask the adopter which scope governance is being set up for. Common cases: repo-wide, a module, a cross-module workstream.
2. **Detect existing state at the scope.** Check whether a governance folder already exists at the target scope, and whether any higher-scope governance is present. If a governance folder exists at the target scope, flag it and defer to an edit flow (out of scope for this command).
3. **Elicit Owner.** Collect name and role. Apply the accountability-not-stakeholder rule; if the adopter names a stakeholder, explain and re-ask.
4. **Elicit DACI.** Collect name + role for each role. Apply defaults for unspecified roles (Driver = Approver = Owner). Accept `TBD` for roles not yet assigned.
5. **Elicit cross-references.** Ask whether any higher-scope governance should be referenced. Skip for repo-wide scope.
6. **Scaffold files.** Produce `governance/README.md` with filled frontmatter + prose, and `decisions/README.md` with the ADR convention. Frontmatter contents come from inputs; prose body uses the template in [`../../templates/governance.md`](../../templates/governance.md).
7. **Confirm.** Show the adopter what was created and invite edits.

## Refusal conditions

- The adopter names a stakeholder as Owner. The command refuses and asks for the accountable role instead.
- A governance folder already exists at the target scope. The command flags the conflict and does not overwrite.
- The scope named by the adopter does not exist in the repository. The command refuses; scope must exist before its governance is scaffolded.

## Non-goals

- Does not create the scope (module, cluster, project). Scope must pre-exist.
- Does not populate governance with policies, ADRs, or other content beyond the README. Those are added subsequently by the scope's owner.
- Does not propagate governance to sub-scopes. Each sub-scope adopts its own governance when it needs to.
- Does not detect contradictions across the governance hierarchy. Contradiction detection is a separate capability performed when LLMs or tools read governance files in context.

## Examples

*(To be added: worked conversations at repo-wide and module scopes, showing the elicitation flow and resulting files.)*
