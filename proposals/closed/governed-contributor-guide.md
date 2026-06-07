---
change: governed-contributor-guide
status: applied
opened: 2026-06-07
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: governed contributor guide

## Intent

The standard ships `templates/contributor-guide.md` containing LLM-agnostic governed content. The adopter's manifest declares `contributor_guide: <filename>` (e.g. `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`). The governed section lives inside that file delimited by sentinels:

```
<!-- oos:governed-start v<version> -->
  ... standard content ...
<!-- oos:governed-end -->
```

`bump` regenerates the content between sentinels from `templates/contributor-guide.md` on every version upgrade. `adhere-to tooling` checks that the declared file contains the sentinel block and that its version matches `standard_version`.

The governed section is load-bearing: it carries the session-start instruction that tells the agent to read the manifest and load all active capabilities and their extensions. This means extensions compose automatically without any adopter-side contributor guide edits.

## Rationale

**The contributor guide mixes standard and adopter content with no boundary.** Standard-level rules (ownership, spec shape, routing) and adopter-specific content (session hooks, plugin allowlists, interface-specific paths) live in the same file with no mechanism to distinguish them. When the standard changes a rule, the adopter must manually locate and update the prose — there is no automation and no conformance check.

**Different LLMs read different files.** Claude Code reads `CLAUDE.md`; Cursor reads `.cursorrules`; GitHub Copilot reads `.github/copilot-instructions.md`. The standard cannot prescribe a filename without excluding adopters on other LLMs. A `contributor_guide` manifest field — declared once, consumed by all standard tooling — decouples the governed content from the interface that delivers it.

**Sentinels make regeneration safe.** The governed section is the standard's concern; everything below the closing sentinel is the adopter's concern. Sentinels let `bump` regenerate the governed section without touching adopter content. Without sentinels, bump would need to diff prose — fragile under every upgrade.

**The governed section eliminates the need for extension propagation into the contributor guide.** If the session-start instruction ("read the manifest, load all active capabilities and their extensions") is in the governed section, then any extension's rules are automatically in scope for every session. Extensions do not push content into the contributor guide; the contributor guide pulls from extensions at session start. The adopter section shrinks over time rather than growing.

## Delta

- New: `templates/contributor-guide.md` — governed content, LLM-agnostic prose
- Update: `specs/tooling/spec.md` — declare `contributor_guide` as an adopter extension point; add `adhere-to tooling` sentinel check
- Update: `specs/adoption-manifest/spec.md` — add `contributor_guide` field to manifest schema (required when `tooling` is active)
- Update: `specs/adoption-manifest/bump.md` — governed section regeneration step (depends on [`bump-command.md`](./bump-command.md))

## Acceptance scenarios

### Governed section present and version-matched passes adhere-to

Given an adopter with `contributor_guide: CLAUDE.md` and `standard_version: "0.2.11"`
When `adhere-to tooling` runs
Then it reads `CLAUDE.md`, finds `<!-- oos:governed-start v0.2.11 -->`, and passes

### Stale version flagged

Given an adopter whose `CLAUDE.md` contains `<!-- oos:governed-start v0.2.10 -->` and `standard_version` is `"0.2.11"`
When `adhere-to tooling` runs
Then it files a `[conformance]` entry: "governed section is at v0.2.10; standard_version is v0.2.11 — run /bump to regenerate"

### Bump regenerates governed section without touching adopter content

Given adopter content below `<!-- oos:governed-end -->`
When `/bump v0.2.11` runs
Then content between sentinels is replaced with new `templates/contributor-guide.md`; everything below `<!-- oos:governed-end -->` is unchanged

### Non-Claude-Code adopter declares different file

Given an adopter with `contributor_guide: .cursorrules`
When `adhere-to tooling` runs
Then it reads `.cursorrules` for the sentinel check; the governed content is identical — only the filename differs

### Session-start loads extensions automatically

Given the governed section contains the session-start instruction to load all active extensions
When a contributor opens a session in a repo that has a `risk-at-scope` extension
Then the agent loads that extension's rules without any adopter-section entry in the contributor guide

## Decision authority

Javier Fernandez (Standard author). Validated against two-adopter scenario (Claude Code / Cursor) on 2026-06-07.
