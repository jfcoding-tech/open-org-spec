# Feedback inbox

A capability of open-org-spec describing how per-scope feedback files work: where they live, how entries are formatted, how addressees are identified, and how entries are resolved.

**Status:** Draft (0.1.0)

## Purpose

A spec-driven repository accumulates observations from contributors — requests for a spec owner to reconsider a decision, flags of inconsistency, proposed directions. Without a canonical inbox shape, every scope re-invents the format; tools that scan inboxes (like the catchup tool) must guess at the convention; and contributors arriving at a new scope cannot immediately tell how to leave a note or who will read it.

This capability defines a single inbox shape reusable at any scope, with addressee conventions that tools can detect reliably.

## Pattern

### Where the inbox lives

Each scope that wants to receive feedback carries a single `feedback.md` file at its scope root. The file is an inbox, not a decision log and not a task list. It holds observations addressed to a named person; the addressee responds and closes the loop.

Absence of a `feedback.md` at a scope means that scope does not maintain a local inbox — contributors route to the nearest higher-scope inbox instead.

### Two addressing modes

Both modes are legitimate. Scopes choose the mode that fits their ownership shape; tools must handle both.

**File-level addressing** — used when the scope has a single named owner. Every entry implicitly addresses that owner; no per-entry addressee marker is needed. The file's header or preamble names the owner. Example: `ai-factory/feedback.md` addressed to the AI Factory Owner.

**Per-entry addressing** — used when the file serves multiple recipients. Each entry carries an explicit addressee arrow: `→ <first-name>` or `→ <full-name>`. Tools scan for this marker to route entries to the right person. Example: `clusters/feedback.md` with entries addressed to specific cross-cluster operators.

A file may mix both modes: a file-level owner receives all entries by default, and specific entries may name a different addressee with the arrow marker.

### Entry formats

**One-liner** — for brief observations that need no context:

```
- YYYY-MM-DD | <author>[ → <addressee>] | <one-line note>
```

**Substantive entry** — for observations that warrant context and a response:

```
## [resolved]? YYYY-MM-DD | <author>[ → <addressee>] — <short title>

**Observation:** what you saw (facts, not interpretations).
**Why this matters:** the rationale — why the addressee should spend time on this.
**Suggested direction (not a decision):** what you'd do if this were yours. Addressee decides whether to adopt.
**If you disagree:** what you'd like the addressee to respond to.
```

The body sections are a suggested shape, not mandatory. Short entries may omit sections that add no value.

**Representation is extension-overridable.** The entry-heading format and the `→ <name>` addressee marker shown above are the defaults; tools depend on them by default. Adopters may declare a different heading or addressee syntax in their extension spec, provided the two addressing modes (file-level and per-entry) remain distinguishable, the resolution marker remains detectable, and the extension declares the mapping for tools that scan inboxes. The capability requires the addressing modes, the date+author convention, and the resolution marker, not the specific syntax. Replacing the two-mode model with a single-mode one, removing the resolution marker, or breaking date+author detection is not authorised by this override — only the form changes; the contract does not.

### Resolution

When an addressee responds — whether adopting, modifying, or declining — their response goes inline under the entry. When the matter is closed, the entry heading is prefixed with `[resolved]` and a pointer is added to the commit, spec, or decision that actioned it (or the reasoning for declining).

One-liner entries are resolved by appending a follow-up line below the original, prefixed with the response date and author.

Resolved entries are not deleted. They form a record of how the scope responded to observations over time.

### Addressee detection for tools

Tools scanning a feedback file to surface inbox items for a specific contributor apply the following rules in order:

1. **Per-entry marker** — look for `→ <name>` in the heading line (case-insensitive, first-name or full-name match). If found, the entry is addressed to that person.
2. **File-level owner** — if the file's header or preamble names a single owner and the contributor matches, all unmarked entries address them.
3. **Digest window** — only entries added within the contributor's digest window (since their last contribution) are surfaced. Previously open entries not touched in the window do not re-appear — the contributor saw them on a prior run.
4. **Skip resolved** — entries prefixed `[resolved]` are excluded.

Tools must handle both addressing modes. A tool that only implements per-entry detection misses file-level-addressed inboxes; a tool that only implements file-level detection misses multi-recipient files.

### Entry types

Entries may carry a `[type]` tag in the heading to signal their origin and expected
response. Tools that file entries use these tags; tools that scan inboxes may filter
by them.

| Tag | Filed by | Meaning | Expected response |
|-----|----------|---------|-------------------|
| `[conformance]` | Conformance agents, `adhere-to` | A spec is missing a required field or section | Spec owner adds the missing content, or records an accepted gap |
| `[gap]` | Agent acting for a contributor | A proposed contribution needs an extension decision before it can be built | Manifest owner responds: `oos:extend <capability>`, proceed without extension, or decline with rationale |
| `[scope-elevation]` | Scope-elevation scanner | An artefact may belong at a higher scope, or the same concept exists at multiple scopes | Higher-scope owner resolves: elevate, consolidate, cross-reference, or confirm in place |
| `[decision-escalation]` | Decision-escalation tool | An open decision is past its staleness threshold with no disposition | Decision owner responds: confirm with date, defer with reason, or reassign |

Tags are optional — untagged entries are legitimate observations with no routing
implication. Tools that scan inboxes must handle both tagged and untagged entries.

### Consent and role assignments

When a feedback entry proposes adding a person to a `people.md` in a role, or assigning a responsibility to a named person, the entry itself is not the consent mechanism. The entry opens the conversation; the named person's inline response closes it. See the [`people`](../people/spec.md) capability for the consent and acknowledgement rule for `people.md` additions specifically.

## What is not prescribed

- **Whether every scope has a feedback file.** Absence is valid. Small scopes with a single active contributor may route feedback directly rather than through a file.
- **The frequency of review.** The addressee reviews at their own cadence. The catchup tool surfaces new entries at session start; no other review mechanism is mandated.
- **The number of open entries.** There is no maximum. An inbox with many open entries is a signal to the scope owner, not a spec violation.
- **Archiving resolved entries.** Keeping them inline is the default. Adopters may move resolved entries to a `## Closed` section at the bottom if the file grows unwieldy.

## Rationale

The feedback inbox is the mechanism by which a spec-driven repository stays alive. Specs are authored by people; people make mistakes, miss edge cases, and need to be challenged. Without a canonical inbox, corrections accumulate in chat, email, or memory — and the spec diverges silently from reality.

The two-mode addressee design (file-level and per-entry) exists because the natural shape varies: a module with a single owner is best served by implicit file-level addressing; a cross-cutting file serving multiple recipients needs explicit arrows. Forcing one mode onto the other produces either over-specified inboxes (arrows on every entry in a single-owner file) or ambiguous ones (no arrows in a multi-recipient file). Both modes must be first-class.

## Adoption

*(An `oos:adopt-feedback-inbox` command is deferred pending a second adopter instance. Until then, create `<scope>/feedback.md` manually, add a header naming the addressee(s), and follow the entry formats above.)*

## Related

- [`../tooling/catchup/spec.md`](../tooling/catchup/spec.md) — the catchup tool depends on this capability for its inbox scanning step.
- [`../people/spec.md`](../people/spec.md) — feedback entries that propose role assignments interact with the people-at-scope consent rule.
- [`../../backlog.md`](../../backlog.md) — "Feedback-inbox as a per-scope capability" (added 2026-04-30). This spec is its graduation.
