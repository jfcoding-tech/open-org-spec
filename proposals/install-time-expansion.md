---
change: install-time-expansion
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: install-time expansion of command templates

## Intent

Two related changes to the `tooling` capability and its `adhere-to` tool, both
serving the same goal — making self-contained commands reliable in automated
contexts where the `open-org-spec` submodule is not initialised.

1. **Install-time expansion.** Establish explicitly that command templates carry
   `{{variable}}` extension points which are resolved **at install time** by
   `adhere-to tooling`, never at runtime by the agent. A self-contained command is
   fully expanded when it is written into the adopter's command directory: every
   variable substituted, every piece of execution logic embedded in the file. The
   command never reads from `open-org-spec/` (the submodule) or from
   `.open-org-spec/extensions/` while it runs. Extension files contribute
   *configuration values* consumed during expansion; they do not contribute
   *execution logic* read at runtime.

2. **Version sentinel in the artefacts check.** Change the conformance check for
   command-template artefacts from `file_exists` to `file_contains`, with the
   sentinel `canonical_spec_version: "{{canonical_spec_version}}"`. A bare
   existence check passes even when the installed file is stale — wrong version,
   outdated logic. The sentinel makes `adhere-to tooling` detect an out-of-date
   installed command and reinstall it from the current template.

## Rationale

**The submodule is not present in automated contexts, so runtime delegation to the
standard cannot be the customisation mechanism.** The `tooling` capability already
states that a command running in an automated context (scheduled, or
`--dangerously-skip-permissions`) must not read from `open-org-spec/specs/` at
runtime, because the submodule is not guaranteed to be initialised there. GitHub
Actions runners are the canonical case: a fresh checkout does not run
`git submodule update --init` unless the workflow asks for it, and even then the
adopter's `.open-org-spec/extensions/` wiring is adopter-private state that a
generic runner cannot be assumed to have resolved. A command that defers any part
of its behaviour to "read the extension and apply it" at runtime therefore has two
failure modes: it fails explicitly (file not found) or — worse — it fails silently,
finding an empty or partial file and proceeding as if no extension existed. Silent
divergence between what the manifest declares and what the command actually does is
exactly the drift the standard exists to prevent.

**The only reliable pattern is a self-contained command with all logic embedded —
but self-containment must not mean loss of customisation.** The tension is real: the
standard wants commands to be generic and reusable, adopters want them tailored to
their org, and automated contexts forbid runtime reads. Resolving runtime reads in
favour of self-containment would, naively, force adopters to fork the template and
hand-edit it — losing the link back to the canonical spec and the ability to
re-sync. Install-time expansion dissolves the tension. The template stays generic
and versioned in the standard. Customisation is expressed as `{{variable}}` points
whose values come from the adopter's extension and manifest. `adhere-to tooling`
resolves those values **once, at install time**, and writes a fully-expanded,
self-contained file. The adopter gets a tailored command; the runtime gets a file
with no external dependencies; the standard keeps a clean template it can version.
The customisation happens — it just happens before the command ever runs, not while
it runs.

**This draws a bright line between configuration and logic.** The proposal makes the
distinction load-bearing. Extension files may supply **configuration values** —
paths, inbox locations, severity thresholds, org-specific vocabulary — that fill
`{{variable}}` slots. Extension files may **not** supply execution logic that the
command reads and interprets at runtime. The reason is that configuration is data
that can be baked in by substitution, whereas logic read at runtime reintroduces the
submodule/extension dependency the whole pattern is designed to remove. If an
adopter's customisation genuinely requires different *logic*, that is a template
variant or a capability extension that changes the template — resolved at install
time like everything else — not a runtime branch. Keeping the line bright is what
lets `adhere-to` guarantee that an installed command is complete and standalone.

**`file_exists` is too coarse a conformance check because it cannot see staleness.**
The artefacts mechanism scaffolds a command when its check fails. With
`check.type: file_exists`, the check passes the moment any file exists at the path —
regardless of its contents, version, or whether the template it was generated from
has since changed. An adopter who installed a command at standard v0.1.2, then
bumped to v0.1.6 where the template gained a new execution step, would keep running
the v0.1.2 logic indefinitely: the file exists, so `adhere-to` never reinstalls it.
The manifest says the command conforms to the active version; the file on disk does
not. This is the same silent-drift failure as runtime delegation, arriving by a
different door.

**A version sentinel turns the existence check into a freshness check at zero extra
machinery.** Every self-contained command already declares
`canonical_spec_version` in its frontmatter (the `tooling` capability requires it
for drift detection). The expansion process knows the version it is installing,
because it substitutes `{{canonical_spec_version}}` from the template. So the
sentinel is already present in every correctly-installed file. Changing the artefact
check to `file_contains` with value
`canonical_spec_version: "{{canonical_spec_version}}"` — where the variable resolves
to the version `adhere-to` is currently installing — makes the check pass only when
the installed file's recorded version matches the version being scaffolded. A stale
file (older version string) fails the check and is reinstalled from the current
template. No new field, no separate manifest, no checksum registry: the version the
command already records *is* the freshness signal, and `file_contains` reads it.

**Reinstall-on-staleness composes correctly with the existing drift machinery.**
`adherence-check tooling` already diffs `canonical_spec_version` against the current
standard version to decide whether a command's logic changed. That check answers
"should a human review this command?" The sentinel check answers a narrower,
mechanical question: "is the file on disk the one this version of `adhere-to` would
generate?" The two are complementary. When a bump carries no behavioural change,
drift detection auto-advances the version and the sentinel check reinstalls the file
with the new (matching) version string — fully automatic. When a bump carries a `!`
behavioural change, drift detection raises a finding for review *and* the sentinel
check will reinstall the corrected template once the manifest owner approves the
bump. Neither check can mask the other: existence is necessary but the sentinel
makes correctness sufficient.

## Delta

Changes land in two specs: the parent `tooling` capability (`specs/tooling/spec.md`)
and the `adhere-to` tool (`specs/tooling/adhere-to/spec.md`).

### 1. Install-time expansion principle (tooling/spec.md)

A new subsection under **Self-contained commands**, after *Declaring the canonical
source*:

#### Install-time expansion

> A self-contained command template carries `{{variable}}` extension points.
> These are resolved **at install time** by `adhere-to tooling` when the command
> file is scaffolded into the adopter's command directory — never at runtime by the
> agent that executes the command.
>
> The contract has three parts:
>
> 1. **No runtime reads of the standard.** A self-contained command never issues
>    read instructions against `open-org-spec/` (the submodule, not guaranteed
>    initialised in automated contexts) or against `.open-org-spec/extensions/`
>    (adopter-private wiring, not guaranteed resolved on a generic runner). All
>    logic the command needs is embedded in the command file by the time it runs.
>
> 2. **Extensions supply configuration, not logic.** A capability extension or the
>    adoption manifest may supply *values* — paths, inbox locations, thresholds,
>    org-specific vocabulary — that fill the template's `{{variable}}` slots during
>    expansion. They may not supply execution logic that the command reads and
>    interprets at runtime. Customisation that requires different logic is a
>    template variant or a capability-extension change to the template, resolved at
>    install time, not a runtime branch.
>
> 3. **Expansion is a single install-time pass.** `adhere-to tooling` resolves every
>    `{{variable}}` (via the existing artefact `variables` sources —
>    `config.yaml#…`, `git_config#…`, `standard#…`) and writes a fully-expanded,
>    standalone file. The installed file contains no unresolved `{{variable}}`
>    tokens and no instruction to read external standard or extension paths.

### 2. `canonical_spec_version` is a template variable

Add `{{canonical_spec_version}}` to the set of recognised template variables, with
its value sourced from `config.yaml#standard_version` (the version `adhere-to` is
installing). The template's frontmatter declares:

```yaml
canonical_spec_version: "{{canonical_spec_version}}"
```

and expansion substitutes the version being installed. This is what makes the
sentinel check (below) self-describing — the file records the exact version it was
expanded from.

### 3. Version sentinel in the artefacts check (adhere-to/spec.md, Step 4)

The artefact `check` for a command-template artefact changes from:

```yaml
check:
  type: file_exists
```

to:

```yaml
check:
  type: file_contains
  value: 'canonical_spec_version: "{{canonical_spec_version}}"'
```

with `canonical_spec_version` resolved (per change 2) to the version being
installed. Effect on Step 4's processing loop:

- **Check** now passes only when the file exists *and* contains the matching
  version sentinel.
- **Scaffold** (on check failure) now covers two cases that `file_exists` conflated:
  the file is absent (install), or the file is present but its version sentinel does
  not match (reinstall from the current template). Both write the expanded template
  to `path`; reinstall overwrites.

A note is added to Step 4 / *How `adhere-to` processes artefacts*: when a
`file_contains` check fails because the file exists with a *different*
`canonical_spec_version`, the scaffold step is a **reinstall** — it overwrites the
stale file with the freshly-expanded template. Reinstall is reported distinctly from
first-install in the Step 5 summary (e.g. "Artefacts scaffolded: 1 installed, 2
reinstalled (stale version)").

### 4. Summary line (adhere-to/spec.md, Step 5)

The *Artefacts scaffolded* summary line gains a reinstall count so the manifest
owner can see when a bump caused command reinstalls, distinct from first-time
installs.

## Acceptance scenarios

### Expanded command runs in GitHub Actions without the submodule

Given a self-contained command installed by `adhere-to tooling`, with all
`{{variable}}` points resolved at install time
And a GitHub Actions workflow that checks out the repo without
`git submodule update --init`
When the command runs on the runner
Then it executes entirely from embedded logic
And it issues no read against `open-org-spec/` or `.open-org-spec/extensions/`
And it does not fail or silently degrade for want of the submodule

### Extension value is baked in at install time, not read at runtime

Given a capability extension that declares a configuration value (e.g. a custom
feedback inbox path) consumed by a command template's `{{variable}}`
When `adhere-to tooling` installs the command
Then the resolved value is written directly into the installed command file
And the installed file contains no instruction to read the extension at runtime

### Runtime logic in an extension is rejected as a gap

Given a proposed extension that supplies execution logic the command would read and
interpret at runtime (not a configuration value)
When `adhere-to tooling` evaluates the capability
Then this is treated as outside the install-time-expansion contract
And surfaced as a gap to the manifest owner: customisation requiring different logic
must be a template variant resolved at install time, not a runtime branch

### Stale command is detected and reinstalled

Given a command installed at standard v0.1.2, recording
`canonical_spec_version: "0.1.2"`
And the manifest's `standard_version` is now `0.1.6`, whose template differs
When `adhere-to tooling` runs and evaluates the artefact check
Then the `file_contains` check for `canonical_spec_version: "0.1.6"` fails against
the v0.1.2 file
And `adhere-to` reinstalls the command from the current template
And the Step 5 summary reports it as a reinstall, not a first install

### Up-to-date command is not reinstalled

Given a command whose recorded `canonical_spec_version` already matches the version
`adhere-to` is installing
When `adhere-to tooling` runs
Then the `file_contains` check passes
And the artefact is skipped (no reinstall, no churn)

### file_exists would have masked the staleness

Given the stale-command scenario above
When the check is the old `file_exists`
Then the check passes because a file exists at the path
And the stale command is never reinstalled — demonstrating the gap this change closes

## Decision authority

The standard author (Javier Fernandez) decides. Both changes are behavioural changes
to self-contained-command runtime semantics and to the `adhere-to` artefact loop, so
the landing commit is `feat!:` (breaking) per the contributing conventions — the
artefact `check.type` change and the new install-time contract both affect runtime
behaviour of derived commands.

## Related

- `specs/tooling/spec.md` — parent capability; *Self-contained commands*, *Declaring
  the canonical source*, and the `## Artefacts` block this proposal amends
- `specs/tooling/adhere-to/spec.md` — Step 4 (artefact scaffolding) and Step 5
  (summary), where the `file_contains` sentinel check and reinstall reporting land
- `specs/adherence-check/spec.md` — `canonical_spec_version` drift detection, which
  the sentinel check complements (review-level vs. freshness-level)
- `specs/tooling/hooks/` — the pre-commit/pre-push hook templates that already use
  `{{variable}}` install-time substitution; this proposal generalises that pattern
  to command templates and makes the no-runtime-read rule explicit
