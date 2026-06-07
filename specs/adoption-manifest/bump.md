# Bump (command)

Invoked as: `/bump [<version>]`
Part of: [`adoption-manifest`](./spec.md) capability.

## Purpose

Upgrade an adopter's repo to a new version of the open-org-spec standard in a single
run, with no manual file editing. The command handles both distribution mechanisms
(`submodule` and `zip`), runs a differential `adhere-to` sweep across all active
capabilities, flags extension review where the standard changed content an adopter's
extension touches, and regenerates the governed section of the contributor guide.

The alternative without this command: manually check out the new submodule tag (or
unpack the zip), run `adhere-to` on each capability individually, regenerate the
governed section by hand, and update `standard_version`. Every adopter performs this
sequence independently and at risk of skipping steps. `/bump` makes the sequence
canonical, complete, and repeatable.

## Preconditions

- `.open-org-spec/config.yaml` exists with a valid `standard_version` and
  `adoption_mechanism` field (refuse if absent — redirect to `oos:adopt-manifest`).
- The running contributor is the manifest owner (refuse otherwise — version upgrades
  are a manifest-owner act).
- For `submodule` adopters: the open-org-spec submodule is present and reachable.
- For `zip` adopters: `incoming_path` is declared in the manifest.

## Inputs

**Submodule adopters:** `/bump v<new-version>` — the target version tag. If omitted,
the command lists available tags and asks.

**Zip adopters:** `/bump` — no version argument needed. The command detects the zip
at `incoming_path` and reads the version from the archive's `VERSION` file.

## Steps

### Step 1 — Get the new version

**Submodule:** check out the target tag inside `open-org-spec/`:
```
git -C open-org-spec fetch --tags
git -C open-org-spec checkout v<new-version>
```
Record `old_version` from the current `standard_version` in `config.yaml`.

**Zip:** detect a `.zip` file at the declared `incoming_path`. If none found, refuse:
"no zip file found at `<incoming_path>` — place the new-version zip there and re-run."
Unpack into a temporary directory, read `VERSION`, set `new_version`. Swap the
unpacked content into `open-org-spec/`. Remove the zip from `incoming_path`.

### Step 2 — Diff active capabilities

For each capability with `status: active` in `config.yaml`, diff its spec between
`old_version` and `new_version`:

```
git -C open-org-spec diff v<old>..v<new> -- specs/<capability>/
```

Produce a capability change map:
- **No diff** → mark as `auto-advance`
- **Diff, no adopter extension** → mark as `adhere-to needed`
- **Diff, adopter has extension** → check overlap (step 3)

### Step 3 — Extension overlap check

For each capability with a diff AND an adopter extension:

1. Read the adopter's extension (path from manifest).
2. Identify which sections of the base spec the extension references or overrides
   (by reading the extension's `## What this extension adds` and any `Extends:`
   pointers to specific sections).
3. Check whether any diffed section in the base spec overlaps with the extension's
   declared scope.
4. If overlap: mark capability as `extension-review needed` — do not auto-advance.
5. If no overlap: mark as `adhere-to needed` (same as no-extension path).

### Step 4 — Run adhere-to on changed capabilities

For each capability marked `adhere-to needed` or `extension-review needed`:

Run `adhere-to <capability>` to surface conformance gaps introduced by the new
version. Gap findings are routed to the relevant spec owners via feedback entries,
following `adhere-to`'s standard routing rules.

For `extension-review needed` capabilities, surface an additional note to the
manifest owner:

> "The `<capability>` capability changed in sections your extension touches — review
> your extension at `.open-org-spec/extensions/<capability>/spec.md` to confirm it
> still makes sense against the new base spec. Update `Extends:` links if section
> paths changed."

### Step 5 — Regenerate the governed section

Read the manifest's `contributor_guide` field to get the adopter's agent-instructions
file path (e.g. `CLAUDE.md`).

1. Read `open-org-spec/templates/contributor-guide.md` (the governed content).
2. Replace `<manifest-owner-name>` with `owner.name` from `config.yaml`.
3. Find the sentinel block in the contributor guide file:
   `<!-- oos:governed-start v... -->` … `<!-- oos:governed-end -->`.
4. Replace the content between the sentinels with the new governed content.
5. Update the version in the opening sentinel: `<!-- oos:governed-start v<new-version> -->`.

If no sentinel block is found: file a `[conformance]` entry to the manifest owner
and skip regeneration — the adopter must add the sentinel block manually first.

### Step 6 — Update standard_version

Update `standard_version` in `.open-org-spec/config.yaml` to `<new-version>`.

### Step 7 — Surface summary

Report to the contributor:

```
/bump complete — v<old> → v<new>

Capabilities: <n> auto-advanced, <n> adhere-to runs, <n> extension reviews needed
Governed section: regenerated in <contributor_guide>
standard_version: updated to <new-version>

Extension reviews needed:
  <capability> — review .open-org-spec/extensions/<capability>/spec.md

Conformance gaps (from adhere-to runs):
  → filed to relevant spec owners via feedback entries
```

## Refusal conditions

- **No manifest.** Redirect to `oos:adopt-manifest`.
- **No `adoption_mechanism` field.** Refuse: "add `adoption_mechanism: submodule`
  or `adoption_mechanism: zip` to `.open-org-spec/config.yaml` before running bump."
- **`adoption_mechanism: zip` but no `incoming_path`.** Refuse with actionable message.
- **`adoption_mechanism: zip` and no zip at `incoming_path`.** Refuse with path.
- **`adoption_mechanism: submodule` and target tag not found.** List available tags.
- **Caller is not the manifest owner.** Refuse — version upgrades are a manifest-
  owner act.

## What bump does not do

- **Does not commit.** The adopter reviews the changes and commits when satisfied.
- **Does not push.** Pushing to origin is the adopter's act.
- **Does not resolve extension conflicts.** Bump surfaces them; the manifest owner
  decides how to resolve.
- **Does not run adhere-to on `auto-advance` capabilities.** If the spec did not
  change, conformance did not change; re-running adhere-to would be noise.

## Rationale

**The current bump workflow is per-adopter and incomplete.** It lives as a manual shell sequence in each adopter's contributor guide. Every adopter copies and maintains it separately. The reference implementation's sequence ran `adhere-to` only on one capability, missing every other active capability with extensions. A standard-level command eliminates per-adopter drift and ensures the full sweep runs on every upgrade.

**Two distribution mechanisms exist and neither is more fundamental than the other.** One adopter uses git submodule; another receives zip files. Handling zip as a per-adopter extension would create two separate copies of a fundamentally identical workflow. Making `adoption_mechanism` a first-class manifest field means the command surface is identical for all adopters and the mechanism choice is a one-time declaration.

**Extensions need differential review, not just conformance.** When the standard changes a capability, an adopter's extension for that capability may now duplicate something the standard fixed, conflict with a renamed field, or miss a new override point. `adhere-to` alone does not catch this. The bump command knows which extensions overlay which base specs via `Extends:` links and diffs precisely the sections that overlap — flagging extension review rather than auto-advancing when there is overlap.

## Related

- [`spec.md`](./spec.md) — manifest schema, `adoption_mechanism` and `contributor_guide` fields.
- [`../tooling/spec.md`](../tooling/spec.md) — contributor guide sentinel convention.
- [`../../templates/contributor-guide.md`](../../templates/contributor-guide.md) — governed section content.
