# Contributing to open-org-spec

Instructions for LLM agents and humans making changes to the standard itself. This file is NOT for adopters — if you are reading this in an adopter's repository context, ignore it and follow the adopter's own CLAUDE.md.

---

## Commit conventions

This repository uses **conventional commits**. Every commit message must follow the format:

```
<type>[!]: <short description>
```

### Types

| Type | When to use |
|---|---|
| `feat` | New capability spec, new command, new section |
| `fix` | Correction to existing spec logic or a bug in a command |
| `docs` | Rewording, clarification, examples, rationale — no behaviour change |
| `chore` | Tagging, version bumps, maintenance |
| `refactor` | Restructuring without behaviour change |

### Breaking changes — use `!`

Append `!` to the type when the change **affects runtime behaviour of self-contained commands** derived from this spec. Specifically, use `!` when:

- An execution step is added, removed, or modified in a tool spec's Pattern section
- A security contract changes (new layer, modified guardrail, changed write scope rule)
- A required field is added or removed from an output format (invocation log, catalogue schema, nudge entry format)
- A shared contract changes (retry topology, observability contract)

Do NOT use `!` for:
- Documentation rewrites that don't change the pattern
- New extension points that adopters opt into
- Rationale additions or clarifications
- Examples added without changing requirements

### Examples

```
feat: add federation capability spec
feat!: add Layer 4 to agent security contract
fix: correct dedup window description in decision-nudge
fix!: change invocation log format to include model field
docs: clarify cascade principle in federation spec
chore: tag v0.1.5
```

---

## Versioning

Versions follow `0.<minor>.<patch>` until the standard stabilises.

| Change | Version bump |
|---|---|
| New capability spec or significant new section | Minor (`0.x.0`) |
| Breaking change to existing spec (`!` commit) | Minor (`0.x.0`) |
| Bug fix or non-breaking addition | Patch (`0.x.y`) |
| Documentation only | Patch (`0.x.y`) |

After committing, tag the release:

```bash
git tag v<version>
git push origin main v<version>
```

---

## Pre-spec design: proposals

Every new capability and every significant behaviour change to an existing capability requires a proposal in `proposals/` before the `feat:` commit. A proposal captures the design rationale while the thinking is live — it becomes the `## Rationale` section of the eventual spec and the audit trail for why the capability works the way it does.

The `## Rationale` section is **required** in every proposal. Write it from the motivation, not the mechanism: what problem does this solve, why this approach over alternatives? A proposal without a rationale section is not ready to apply.

When drafting a proposal, check `backlog.md` for any related entries and reference them in `## Related`. A proposal that addresses a backlog entry should note `backlog: <entry-slug>` in its frontmatter so the connection is machine-readable.

See [`proposals/README.md`](./proposals/README.md) for the full lifecycle and promotion checklist.

---

## Promoting capabilities from an adoption

When promoting a capability from an adoption's `.open-org-spec/extensions/` into this standard:

1. Extract the generic core — remove all adopter-specific content (names, paths, org structure). The adopter's wiring stays in their `extensions/<capability>/<adopter-slug>/spec.md`.
2. Set `Status: Active` on the promoted spec.
3. Remove the "Promotion path" section — it is no longer relevant.
4. Update relative links to work from the spec's new location under `specs/`.
5. Copy `## Rationale` from the proposal (or the extension's rationale notes) into the promoted spec.
6. Move the proposal to `proposals/closed/`.
7. Use a `feat:` commit unless the promotion includes a breaking change to an existing spec.
8. Tag a new minor version.
9. **Update `README.md` — `## Contents`**: add the new capability with its slug and a one-line description.
10. **Update `README.md` — `## Status`**: add a changelog entry for the new version describing what was added.
11. **Review `WHY.md`**: if the new capability changes the value proposition or adds a materially new use case, update the relevant section. Not every promotion requires a WHY update — only those that change what the standard is for.
12. **Update `backlog.md`**: close any backlog entries that this promotion addresses. If the capability is partial, note what remains deferred.

---

## What belongs in this repo

Only generic, reusable content that applies across organisations. If you are unsure whether something is generic or adopter-specific, ask: "would this make sense in a completely different organisation with a different structure?" If no, it does not belong here.

---

## Related

- [`AGENTS.md`](./AGENTS.md) — entry point for LLM agents adopting the standard (not for contributors)
- [`README.md`](./README.md) — overview for humans
