# Run the adherence check

Invoked as: `oos:check <scope>`
Part of: [`adherence-check`](./spec.md) capability.

## Purpose

Run the adherence check against a target scope and produce a structured report of findings against the `governance-at-scope` schema. Read-only.

## Preconditions

- The target scope path exists in the repository.
- The repository declares conformance to `governance-at-scope`.

## Inputs

- **Scope.** A path in the repository at which governance may exist (repository root, a module path, a cross-module workstream). If omitted, defaults to the repository root.

## Outputs

- A **report** with zero or more **findings**, conforming to the shape declared in [`spec.md`](./spec.md#findings-are-machine-readable). A report with zero findings indicates conformance within the check's v0 limits.

## Steps

1. **Identify the target scope.** Confirm the scope path exists; if it does not, refuse.
2. **Walk the governance hierarchy.** From the target scope upward, collect governance folders that apply.
3. **Validate target frontmatter.** If `<target>/governance/README.md` exists, parse its frontmatter and validate required fields. Emit `gap` findings for missing fields, citing the rule.
4. **Validate cross-reference integrity.** For each path in `cross_references`, verify it resolves to an existing `governance/` folder. Emit `violation` findings on broken references.
5. **Check sibling `decisions/` folder.** If `governance/` exists at the target, check for a peer `decisions/` folder. Emit a `gap` finding if missing.
6. **Role-name sweep.** For each DACI entry at the target, compare role names against higher-scope DACI entries. Emit `warning` findings on exact matches without a documented exception.
7. **Best-effort contradiction detection.** Walk the hierarchy pairwise. Emit `violation` findings on direct field-value conflicts between adjacent scopes.
8. **Emit the report.** Return the structured YAML report. The LLM renders it for the adopter.

## Refusal conditions

- The target scope path does not exist.
- The repository does not declare conformance to `governance-at-scope`.

## Non-goals

- Does not mutate any file.
- Does not validate accountability semantics (whether the named owner is genuinely accountable vs. a stakeholder) — field presence only.
- Does not detect prose-body contradictions.
- Does not follow cross-references into other repositories.
- Does not propose fixes.

## Examples

*(To be added: a worked run at repo-wide scope against a reference implementation.)*
