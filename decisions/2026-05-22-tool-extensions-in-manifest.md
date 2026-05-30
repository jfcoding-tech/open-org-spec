# Tool extensions in the adoption manifest

**Status:** Accepted
**Date:** 2026-05-22
**Decision owner:** Javier Fernandez (open-org-spec author)

## Context

The `adoption-manifest` capability lets an adopter declare one extension per capability via the `extension:` field. The `tooling` capability is the first to contain named sub-tools (currently `catchup` and `adhere-to`) — and the first to surface a real adopter need to extend a specific tool without restating tooling-wide concerns.

A reference implementation's `/catchup` carries adopter-specific behaviour: contributor modes, multi-repo support, channel nudges, additional role headers, and adopter-specific shared-model files. These behaviours are not tooling-wide — they apply only to `catchup`. The existing `extensions/tooling/spec.md` is the wrong home: it declares interface paths and relay shapes that apply to all tools.

Three options were weighed:

1. **Append to existing tooling extension** — add a per-tool subsection inside `extensions/tooling/spec.md`. Zero schema work. Conflates tooling-wide concerns (paths, relay shapes) with tool-specific behaviour (catchup's channels nudge). File grows incoherently as more tools accumulate extensions.

2. **Separate file + extend manifest schema** — `extensions/tooling/catchup/spec.md` declared via a new `tool_extensions:` map in the manifest. Small additive schema change. Mirrors the standard's hierarchy (`tooling/catchup/spec.md` → `extensions/tooling/catchup/spec.md`). Generalises for future tools.

3. **Catchup as its own capability slug** — promote the tool to a top-level manifest entry. No schema change, but erases the capability-vs-tool distinction the standard preserves. Cascades: every future tool would have the same claim.

## Decision

Adopt option 2. Add an optional `tool_extensions:` map to the per-capability manifest entry, where each key is a tool slug (matching the tool's folder name under the capability) and each value is a path to the adopter's extension for that tool. Tool extensions live at `.open-org-spec/extensions/<capability>/<tool>/spec.md`, mirroring the standard's path structure. The manifest's `extension:` field continues to carry capability-wide adopter concerns; `tool_extensions:` adds per-tool overlay without disturbing it.

Agents loading capability rules read base capability + capability extension + any declared tool extensions, in that order. Per-tool extensions follow the same Add / Refine / Override rules as capability extensions: Override requires the base tool spec to explicitly mark the field overridable.

## Consequences

**Positive:**
- Adopter extension structure mirrors the standard's hierarchy. A contributor reading `.open-org-spec/extensions/` can trace each file back to a specific standard path.
- Capability extensions stay focused on capability-wide concerns; tool extensions stay focused on tool-specific behaviour. The boundary survives growth.
- Generalises for every future tool under any capability without additional schema work.
- The capability-vs-tool distinction is preserved in the manifest — the manifest still tracks capabilities, not tools.

**Negative:**
- One small additive change to the manifest schema. Existing manifests remain valid; `tool_extensions:` is optional.
- Adopters with a single tool extension have a slightly heavier YAML structure than they would under option 1 (one extra map level).

**Adoption impact:**
- Existing adopters with no tool extensions need no change.
- Adopters adding their first tool extension declare it via the new map. The adoption-manifest spec carries an example.
- The `tooling/spec.md` capability gains a pointer to this mechanism for discoverability.

## Related

- [`../specs/adoption-manifest/spec.md`](../specs/adoption-manifest/spec.md) — schema change landed in this commit; see "Per-tool extensions" section.
- [`../specs/tooling/spec.md`](../specs/tooling/spec.md) — pointer added to "Per-tool adopter extensions" paragraph.
- First exercise of this mechanism: a reference implementation's catchup extension at `.open-org-spec/extensions/tooling/catchup/spec.md`.
