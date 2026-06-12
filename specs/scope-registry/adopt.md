# Adopt scope registry (command)

Invoked as: `oos:adopt-scope-registry`
Part of: [`scope-registry`](./spec.md) capability.

## Purpose

Guide an adopter through first-time activation of the scope-registry capability. Discovers all active scopes in the adoption, surfaces gaps (missing `feedback.md`, missing `people.md` lead declaration), confirms the discovered scope list with the adopter, then generates `governance/catalogue/scopes.yaml` — the machine-readable catalogue that other capabilities (risk-at-scope, people-catalogue, conformance agents) use to resolve `<type>/<slug>` scope references without walking the repo.

The command activates the capability in the manifest and writes the catalogue. After it runs, any agent resolving a scope reference reads the catalogue rather than traversing folder paths.

## Preconditions

- **The adoption manifest exists** at `.open-org-spec/config.yaml`. If absent, refuse and redirect to `oos:adopt-manifest`.
- **`governance-at-scope` is active** in the manifest. The programme-level entry in the catalogue points to `governance/feedback.md` as its inbox; that file must exist. If absent, refuse and redirect to `oos:adopt-governance` at repo-wide scope.
- **`people` is active** in the manifest. The catalogue reads the `Lead` from each scope's `people.md` lead table. Without the people capability active, lead resolution is undefined. If absent, refuse and direct the adopter to activate `people` first.
- **`feedback-inbox` is active** in the manifest. The catalogue records each scope's `feedback_inbox` path; routing downstream relies on this capability's conventions. If absent, refuse and direct the adopter to activate `feedback-inbox` first.
- **`scope-registry` is not already active** in the manifest. If it is, redirect to `oos:adhere-to scope-registry` — re-running activation against an existing capability is a conformance pass, not first-time setup.

## Inputs

The command does not elicit free-form input. All inputs are read from the repo. The single adopter decision is **confirmation** after Step 3's discovery table is shown.

Optional override:

- **Catalogue output path** — defaults to `governance/catalogue/scopes.yaml`. Adopters may declare an alternative path in the manifest's `scope-registry.catalogue_path` field. If already set, the command reads it; if not set, the command uses the default and records it.

## Steps

### Step 0 — Verify preconditions

Read `.open-org-spec/config.yaml`. Check each precondition in order. Refuse with a specific message on the first failure. Do not proceed past a refusal.

### Step 1 — Read the scope tree

Determine which structural folders to walk. In order of precedence:

1. If the manifest declares an `observability.extension` and that extension file contains a scope tree table, read the folder roots from the table. This is the most precise source — it reflects the adopter's actual folder layout, including non-standard root names.
2. If no scope tree is declared, apply the default heuristics for each structural type:
   - **Clusters** — immediate subdirectories of `clusters/`, excluding `governance/`, `context/`, `_template/`, `closed/`.
   - **Functions** — immediate subdirectories of `functions/`, excluding `_template/`, `closed/`.
   - **Projects** — immediate subdirectories of `projects/`, excluding `_template/`, `closed/`.
   - **Modules** — folders not covered by the above that are declared in the manifest or match known module patterns (`ai-factory/`, `cloudops/`). Walk only one level.
   - **Programme** — always one entry. Path is `.` (repo root), slug is `programme`, feedback inbox is `governance/feedback.md`.

For each discovered candidate folder, include it as a scope entry only if it contains at least one of: a `README.md`, a `spec.md`, or a `people.md`. Bare empty directories are excluded.

Closed scopes — any folder inside a `closed/` subfolder, or any folder whose `README.md` or `spec.md` frontmatter declares `status: closed` — are included in discovery with `status: closed` but are flagged separately. They appear in the catalogue but are not routing targets.

### Step 2 — Resolve scope fields

For each discovered scope, resolve the four fields the catalogue requires:

| Field | Resolution |
|---|---|
| `type` | Inferred from the structural folder: `clusters/` → `cluster`; `functions/` → `function`; `projects/` → `project`; declared module pattern → `module`; repo root → `programme`. |
| `slug` | The folder's immediate directory name. For `programme`, the slug is `programme`. |
| `path` | Relative path from the repo root to the scope folder. For `programme`, the path is `.`. |
| `feedback_inbox` | Path to `<scope>/feedback.md` if the file exists; `null` if absent. |
| `lead` | Read the scope's `people.md`. If the lead table has a non-`TBD` Name cell, use that value. If the file is absent, or the Name cell is `TBD`, record `TBD`. For `programme`, the lead is the manifest owner's name. |
| `status` | `active` unless the scope is in a `closed/` folder or its frontmatter declares `status: closed`, in which case `closed`. |

### Step 3 — Surface discovery results and gaps

Display two outputs to the adopter before proceeding.

**Discovery table** — one row per scope, columns: Type, Slug, Lead, Feedback inbox, Status.

Example:

```
Discovered 9 scopes:

Type        Slug                         Lead                  Feedback inbox                              Status
cluster     product-development          Yaiza Temprado        clusters/product-development/feedback.md    active
cluster     customer-acquisition-growth  Collette Doyle        clusters/customer-acquisition-growth/…      active
cluster     customer-lifecycle           Howard Tunnicliffe    clusters/customer-lifecycle/feedback.md     active
function    revenue                      Howard Tunnicliffe    functions/revenue/feedback.md               active
module      ai-factory                   TBD                   ai-factory/feedback.md                      active
project     agentic-coach-phase-3        TBD                   null                                        active
project     sophie-content-pairing       Yaiza Temprado        projects/sophie-content-pairing/feedback.md active
project     busuu-live-claire            TBD                   null                                        closed
programme   programme                    Javier Fernandez      governance/feedback.md                      active
```

**Gaps list** — flag each of the following; group by severity:

| Severity | Condition | Message |
|---|---|---|
| `warning` | `feedback_inbox: null` on an active scope | "No `feedback.md` at `<path>`. Routing agents will fall back to the nearest parent inbox until one is created." |
| `warning` | `lead: TBD` on an active scope | "Lead not declared in `<path>/people.md`. Catalogue will record `TBD`; update `people.md` to resolve." |
| `info` | `status: closed` | "Scope `<slug>` is closed and will appear in the catalogue with `status: closed`. Routing agents skip it." |

Then ask the adopter:

> The catalogue will be written with these N scopes. Any scopes missing from the list? Any to exclude? Confirm to proceed, or name corrections.

Accept corrections (add a scope by path, exclude a slug) before proceeding. Apply corrections to the discovered list and re-display the table if changes were made.

Do not proceed until the adopter confirms.

### Step 4 — Generate the catalogue

Write the catalogue to the resolved output path (default: `governance/catalogue/scopes.yaml`).

Format:

```yaml
# Scope registry catalogue
# Generated by oos:adopt-scope-registry on YYYY-MM-DD.
# Do not edit by hand — regenerate with oos:adhere-to scope-registry.
generated: YYYY-MM-DDTHH:MMZ
scopes:
  - type: cluster
    slug: product-development
    path: clusters/product-development
    feedback_inbox: clusters/product-development/feedback.md
    lead: Yaiza Temprado
    status: active
  # … one entry per discovered scope …
```

Sort entries: active scopes before closed scopes; within each group, alphabetically by type then slug.

If the output directory does not exist (`governance/catalogue/`), create it. If the output file already exists (unexpected at first activation), refuse overwrite and surface the conflict — do not silently replace.

### Step 5 — Update the manifest

Add or update the `scope-registry` entry in `.open-org-spec/config.yaml`:

```yaml
scope-registry:
  status: active
  activated: YYYY-MM-DD   # today's date
  catalogue_path: governance/catalogue/scopes.yaml  # omit if using the default
```

If the manifest already has a `scope-registry` entry at status `proposed`, change its `status` to `active` and add `activated`. Do not touch any other manifest entries.

This edit requires the running contributor to be the manifest owner (Javier Fernandez per the manifest's `owner` field), or another contributor with the manifest owner's explicit consent recorded in the current conversation. If neither condition holds, refuse the manifest edit, surface the catalogue file written in Step 4, and instruct the contributor to ask the manifest owner to complete Step 5.

### Step 6 — Wire commands

For each command file the capability declares (`adopt.md`, and any `new.md`, `regenerate.md`, or other `<verb>.md` files at `open-org-spec/specs/scope-registry/`), create a relay at the adopter's command path (`.claude/commands/<command-name>.md` for Claude Code). Add a row to the adopter's commands README under "Standard commands (from active capabilities)" linking the relay to the canonical spec.

Skip relay creation if the relay file already exists.

### Step 7 — Surface summary

Display a final summary:

```
scope-registry activated.

Scopes catalogued: N (M active, K closed)
Catalogue written: governance/catalogue/scopes.yaml
Manifest updated: .open-org-spec/config.yaml — scope-registry: active

Gaps flagged:
  warnings: N  (missing feedback.md or TBD lead — see list above)
  info:     K  (closed scopes included but not routed)

Commands wired: N relays created in .claude/commands/

Next steps:
  1. For each warning above, create the missing feedback.md or update the
     people.md lead table. Then run oos:adhere-to scope-registry to regenerate.
  2. Any capability that resolves scope references (risk-at-scope, people-catalogue)
     now reads governance/catalogue/scopes.yaml — no repo traversal required.
  3. When scopes are added or renamed, run oos:adhere-to scope-registry to
     keep the catalogue current.
```

## Refusal conditions

- **Manifest absent.** Redirect to `oos:adopt-manifest`.
- **Required dependency not active** (`governance-at-scope`, `people`, `feedback-inbox`). Named the missing capability; redirect to its adopt command.
- **`scope-registry` already active.** Redirect to `oos:adhere-to scope-registry`.
- **Adopter does not confirm** after Step 3. Abort without writing any file.
- **Catalogue file already exists at output path.** Refuse overwrite; surface the conflict and ask the adopter whether to proceed with `oos:adhere-to scope-registry` instead.
- **Running contributor is not the manifest owner and no explicit consent is recorded.** Write the catalogue (Steps 4 and 6) but refuse the manifest edit (Step 5); instruct the contributor to ask the manifest owner to complete it.

## What is not prescribed

- **The frequency of catalogue regeneration.** Once at activation is required. Subsequent regeneration is on demand (via `oos:adhere-to scope-registry`) or automated (e.g. a scheduled agent). The standard does not mandate a cadence.
- **Whether every discovered scope gets a `feedback.md` before activation.** Gaps are surfaced as warnings, not blockers. The catalogue records `feedback_inbox: null` for scopes without one; agents fall back to the nearest parent inbox. Resolving the warnings is the adopter's choice.
- **Whether the catalogue output path is `governance/catalogue/scopes.yaml`.** Adopters may declare an alternative in the manifest. The default is used when nothing is declared.
- **Whether the adopter corrects TBD leads before proceeding.** Step 3 surfaces them as warnings. The catalogue is valid with `TBD` leads; routing uses `feedback_inbox`, not `lead`.

## Related

- [`spec.md`](./spec.md) — the scope-registry capability spec; defines the catalogue schema, scope reference format, and resolution contract for agents.
- [`../../adoption-manifest/spec.md`](../../adoption-manifest/spec.md) — the manifest this command reads and updates.
- [`../../governance-at-scope/spec.md`](../../governance-at-scope/spec.md) — required dependency; the programme-level governance inbox is the fallback routing target for unresolved scope references.
- [`../../people/spec.md`](../../people/spec.md) — required dependency; the catalogue reads lead names from `people.md` lead tables.
- [`../../feedback-inbox/spec.md`](../../feedback-inbox/spec.md) — required dependency; the catalogue records each scope's `feedback.md` path using this capability's conventions.
- [`../../tooling/adhere-to/spec.md`](../../tooling/adhere-to/spec.md) — the conformance tool re-run after activation to keep the catalogue current; invoked as `oos:adhere-to scope-registry`.
- [`../../risk-at-scope/spec.md`](../../risk-at-scope/spec.md) — primary consumer of scope references; resolves `scope: <type>/<slug>` fields via the catalogue generated here.
