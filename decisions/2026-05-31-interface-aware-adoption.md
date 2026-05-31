# Interface-aware adoption bootstrap

**Status:** Accepted
**Date:** 2026-05-31
**Decision owner:** Javier Fernandez (open-org-spec author)

## Context

The standard is interface-agnostic, but the first real autonomous adoption on a non-Claude-Code interface exposed that the bootstrap (`oos:adopt-manifest`) silently assumed Claude Code conventions. An adopter on **GitHub Copilot** ran the bootstrap and:

- got a `CLAUDE.md` at the repo root — which Copilot never reads (its agent-instructions file is `.github/copilot-instructions.md`);
- got no command artefacts, because the relay model is `.claude/commands/`-shaped and has no obvious mapping to Copilot;
- got no `governance/` folder despite activating `governance-at-scope` — the activation chain wasn't carried to completion (less-agentic interfaces are likelier to drop steps in a long autonomous run), and the spec described the chain too loosely to force it.

The "(or the interface's equivalent)" hand-wave in `adopt.md` was never resolved into concrete paths, so an interface-agnostic *standard* produced an interface-specific *failure*.

## Decision

Make the bootstrap explicitly interface-aware:

1. **Elicit the LLM interface as the first bootstrap input**, and carry a known-mappings table (Claude Code, GitHub Copilot, Cursor, "other → ask") resolving three things: the agent-instructions file path, the command mechanism, and the session-hook availability.
2. **Write the contributor guide at the interface's path** (e.g. `.github/copilot-instructions.md`), not a hardcoded `CLAUDE.md`.
3. **Wire command artefacts only where the interface supports them** (relay files for Claude Code, prompt files for Copilot); where there is no command mechanism, record invoke-by-spec-reference in the commands README rather than fabricating files the interface ignores.
4. **Activate capabilities one at a time and verify each scaffolding landed** (e.g. `governance-at-scope` must have produced `governance/README.md` + `decisions/`) before moving on — never silently skip. Recommend activating one or two capabilities matched to a real use case rather than all at once.

## Consequences

**Positive:**
- Adopters on any interface get files their tool actually reads; the interface-agnostic claim becomes operational, not aspirational.
- The verified, one-at-a-time activation is robust to less-agentic interfaces that previously dropped steps.

**Negative:**
- The interface table is a maintenance surface — new interfaces or changed conventions need updating. Mitigated by the "other → ask the adopter" fallback, which keeps the bootstrap working for unlisted interfaces.

## Related

- [`../specs/adoption-manifest/adopt.md`](../specs/adoption-manifest/adopt.md) — the bootstrap command, with the interface-conventions table.
- [`../templates/README.md`](../templates/README.md) — wiring guidance, now naming per-interface command locations.
