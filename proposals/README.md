# Proposals

Pre-spec design records. A proposal captures the rationale, intent, and acceptance criteria for a planned change to the standard before the `feat:` commit lands. It is the audit trail for why a capability works the way it does.

## Lifecycle

```
proposals/<slug>.md          ← design and review
       ↓  feat: commit
specs/<capability>/spec.md   ← rationale migrates here (## Rationale section)
       ↓
proposals/closed/<slug>.md   ← proposal archived, not deleted
```

## When to write a proposal

- New capability spec
- Significant new section in an existing capability (behaviour change)
- New command under an existing capability

Not required for: bug fixes, documentation rewrites, rationale additions to existing specs.

## Format

Use [`../templates/proposal.md`](../templates/proposal.md). The `## Rationale` section is required for all proposals — it is the content that will live in the promoted spec. Write it for the spec reader, not for the design conversation.

## Promotion checklist

When a proposal is ready to land as a `feat:` commit:

1. Write the spec under `specs/<capability>/`.
2. Copy `## Rationale` from the proposal into the spec verbatim.
3. Move this proposal file to `proposals/closed/<slug>.md`.
4. Commit: `feat: <short description>` (or `feat!:` if breaking).
5. Tag a new version.

## Adopter-originated proposals

Adopters who want to propose a change to the standard stage the proposal in their own repo at `.open-org-spec/proposals/<slug>/proposal.md`. The standard author reviews and, if accepted, promotes it here (extracting the generic core, removing adopter-specific content) before the `feat:` commit.
