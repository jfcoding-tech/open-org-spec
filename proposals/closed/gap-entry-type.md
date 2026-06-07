---
change: gap-entry-type
status: applied
opened: 2026-06-07
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: [gap] entry type + governed section operative rule

## Intent

Add a `[gap]` entry type to the `feedback-inbox` vocabulary. A gap entry is filed when a contributor proposes something that base specs and current extensions do not cover, before any implementation. Gap entries route to the manifest owner's feedback inbox. The manifest owner decides: trigger `oos:extend`, decline with rationale, or proceed without extension.

The governed section of the contributor guide (see [`governed-contributor-guide.md`](./governed-contributor-guide.md)) carries an operative rule:

> When a contributor proposes something that base specs and current extensions do not cover, do not implement. File a `[gap]` entry to the manifest owner's feedback inbox and stop.

The mechanism triggers on a narrow boundary:

- Writes to `open-org-spec/` (the standard directory in the adopter repo)
- Writes to `.open-org-spec/extensions/<file>` where the file's declared `**Owner:**` is not the current contributor
- Edits to capability entries in `.open-org-spec/config.yaml`

It does NOT trigger on ordinary spec creation in `clusters/`, `projects/`, `ai-factory/`, or equivalent content areas.

## Rationale

**Contributors jump from observation to solution, bypassing the manifest owner.** Analysis of a reference-implementation contributor's commits found two cases where direct implementation created cleanup work: writing into a non-existent path in the standard directory (corrected the next day by the manifest owner), and modifying an owned extension without consent (accepted post-hoc but bypassing the ownership rule). Both would have been caught by an agent-level gate at the point of the write.

**Documentation does not help contributors who do not know the process exists.** A contributor who identifies a gap will not search for a contribution process before building — they will build. The governed section rule makes the agent the enforcement point at the moment the contributor proposes an action, without requiring prior knowledge of the process.

**The mechanism must be narrow to avoid friction.** The same contributor analysis found two cases where a broad gate would have been unhelpful: creating role specs within the contributor's own scope, and adding cross-references to a file they had standing to edit. Ordinary content work — even work in domains the standard governs — does not need routing through the manifest owner. The trigger scope is limited to the `open-org-spec/` and `.open-org-spec/extensions/` governance boundary, where the manifest owner's consent is non-negotiable.

## Delta

- Update: `specs/feedback-inbox/spec.md` — add `[gap]` to the entry-type vocabulary with its routing convention
- Update: `templates/contributor-guide.md` — add the operative agent rule (depends on [`governed-contributor-guide.md`](./governed-contributor-guide.md))

## Acceptance scenarios

### Agent intercepts a write to the standard directory

Given a contributor proposes creating a file under `open-org-spec/`
When the agent is about to create the file
Then the agent stops, files a `[gap]` entry to the manifest owner describing what the contributor needs, and does not create the file

### Agent intercepts modification of an owned extension

Given a contributor proposes editing an extension file whose `**Owner:**` is not them
When the agent is about to write the file
Then the agent stops, files a `[gap]` entry to the declared owner, and does not edit the file

### Agent does not intercept ordinary content creation

Given a contributor proposes creating a new project spec at `projects/new-initiative/spec.md`
When the agent is about to create the file
Then the agent proceeds — ordinary content work; no gap entry filed

### Manifest owner resolves a gap entry

Given a `[gap]` entry in the manifest owner's feedback inbox
When the manifest owner reads it
Then they respond with one of: `oos:extend <capability>`, "proceed without extension — rationale: <reason>", or "covered by <existing spec> — see <link>"

## Decision authority

Javier Fernandez (Standard author). Mechanism scope validated against 4 real contributor commits in a reference implementation; 2 of 4 warranted interception, 2 did not. Narrow scope derived from that analysis. 2026-06-07.
