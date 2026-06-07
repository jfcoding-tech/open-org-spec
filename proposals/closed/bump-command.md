---
change: bump-command
status: applied
opened: 2026-06-07
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: bump command + adoption_mechanism field

## Intent

Introduce a `bump` command under `adoption-manifest` that encapsulates the full version-upgrade workflow as a single operation. Add `adoption_mechanism: submodule | zip` as a first-class manifest field and `incoming_path` as the zip adopter's inbox location.

The command: detects the new version (git tag checkout for submodule adopters; zip detection at `incoming_path` for zip adopters) → diffs every active capability's spec between old and new standard version → auto-advances unchanged capabilities → runs `adhere-to` on changed capabilities → flags extension review where base spec changes overlap with an adopter's extension → regenerates the governed section of the contributor guide (see [`governed-contributor-guide.md`](./governed-contributor-guide.md)) → updates `standard_version` in `config.yaml`.

## Rationale

**The current bump workflow is per-adopter and incomplete.** It lives as a manual shell sequence in each adopter's contributor guide. Every adopter copies and maintains it separately. The reference implementation's sequence ran `adhere-to` only on one capability, missing every other active capability with extensions. A standard-level command eliminates per-adopter drift and ensures the full sweep runs on every upgrade.

**Two distribution mechanisms exist and neither is more fundamental than the other.** One adopter uses git submodule; another receives zip files. Handling zip as a per-adopter extension would create two separate copies of a fundamentally identical workflow. Making `adoption_mechanism` a first-class manifest field means the command surface is identical for all adopters and the mechanism choice is a one-time declaration.

**Extensions need differential review, not just conformance.** When the standard changes a capability, an adopter's extension for that capability may now duplicate something the standard fixed, conflict with a renamed field, or miss a new override point. `adhere-to` alone does not catch this. The bump command knows which extensions overlay which base specs (via `Extends:` links) and diffs precisely the sections that overlap — flagging extension review rather than auto-advancing when there is overlap.

## Delta

- New: `specs/adoption-manifest/bump.md` — the command spec
- Update: `specs/adoption-manifest/spec.md` — add `adoption_mechanism` (required; `submodule | zip`), `incoming_path` (required when `adoption_mechanism: zip`) to manifest schema

## Acceptance scenarios

### Submodule adopter runs bump

Given an adopter with `adoption_mechanism: submodule` and `standard_version: "0.2.10"`
When they run `/bump v0.2.11`
Then the submodule is checked out to tag `v0.2.11`, all active capabilities are diffed between versions, `adhere-to` runs on changed ones, the governed section in the declared `contributor_guide` file is regenerated, and `standard_version` is updated in `config.yaml`

### Zip adopter runs bump

Given an adopter with `adoption_mechanism: zip`, `incoming_path: .open-org-spec/incoming/`, and a zip present at that path
When they run `/bump`
Then the zip is unpacked into `open-org-spec/`, the same adhere-to sweep and governed section regeneration runs, the zip is removed from `incoming_path`, and `standard_version` is updated

### Missing incoming_path refused

Given an adopter with `adoption_mechanism: zip` and no `incoming_path` in the manifest
When they run `/bump`
Then the command refuses: "adoption_mechanism is zip but incoming_path is not declared in config.yaml"

### Extension overlap flagged for review

Given an adopter whose `project` extension overrides `## Close criterion`, and the new standard version modifies that section
When bump runs
Then the `project` capability is flagged "extension review needed — base spec changed in a section your extension touches" rather than auto-advancing

### Unchanged capabilities auto-advance

Given 8 of 10 active capabilities have no spec changes between versions
When bump runs
Then those 8 are marked "no change — auto-advanced" with no `adhere-to` run

## Decision authority

Javier Fernandez (Standard author). Validated against reference-implementation bump workflow 2026-06-07.
