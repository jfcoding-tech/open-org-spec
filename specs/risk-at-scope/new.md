# New risk (command)

Invoked as: `oos:new-risk` (slash form: `/new-risk`)
Part of: [`risk-at-scope`](./spec.md) capability.

## Purpose

Scaffold a conformant risk record at a chosen scope. The command elicits the risk's fields, suggests the next available `R-NNN` id from the risk registry, verifies the contributor is declared at the target scope, and writes a `risks/YYYY-MM-DD-slug.md` file with `status: open` and a derived `rag`. It turns a raised concern into a tracked, escalatable record on disk.

This command creates the record; it does not disposition the risk. Disposition (defer, accept, mitigate, close) follows the lifecycle in [`spec.md`](./spec.md#status-lifecycle) and, for `accepted`, requires a decision record the command does not produce.

## Preconditions

- The adopter's repository is conformant with open-org-spec, or is in the process of adopting conformance.
- The target scope exists, and carries either a `people.md` or a DACI declaration (the command does not create scopes or membership).
- A reachable `feedback.md` exists at the scope or a higher scope, so the [escalation contract](./spec.md#escalation-contract) has somewhere to write. If none exists, the command warns (escalation will have no destination until one is created).

## Inputs (elicited from the contributor)

1. **Title.** A short label for the risk.
2. **Description.** Free text: what could go wrong and why it matters.
3. **Owner(s).** One or more named people accountable for dispositioning the risk. Each must be declared at the target scope (`people.md` or DACI); see Step 3.
4. **Escalation threshold.** Integer days of inactivity before the risk escalates. The command offers the scope/repo default (an [extension point](./spec.md#extension-points), e.g. 30) as the suggested value, letting the contributor override.
5. **Scope.** Where should this risk live? The command prompts for a `scope` value in the form `<type>/<slug>` (e.g. `cluster/product-development`, `project/sophie-content-pairing`). It does not infer scope silently.

   **Type vocabulary** — the contributor must choose one of:
   | Type | Meaning |
   |------|---------|
   | `cluster` | A line-of-business cluster (e.g. `cluster/customer-lifecycle`) |
   | `function` | A cross-cutting function or shared service (e.g. `function/revenue`) |
   | `project` | A time-boxed initiative (e.g. `project/iso-42001`) |
   | `module` | A sub-unit within a cluster or function |
   | `programme` | Repo-root level — for risks that cut across the whole organisation |

   **When `type` is `programme`** the `scope` field is required in the record's YAML frontmatter; the command writes `scope: programme/root` unless the contributor supplies a different slug.

   **For all other types** the `scope` field is optional in the frontmatter (the file's path already implies it), but the command records it when supplied.

   **Looking up valid scopes.** If `governance/catalogue/scopes.yaml` exists in the repository, the command offers to list the declared scopes so the contributor can pick one by name rather than typing it free-form. If the file is absent, the command proceeds with the contributor's free-form input.

   **Path inference.** If the contributor is already working within a recognisable scoped folder (e.g. `clusters/foo/`, `projects/bar/`), the command offers to derive `scope` from the path and asks the contributor to confirm or override rather than type it from scratch.

The `id` and `rag` are **not** elicited — `id` is suggested from the registry (Step 2) and confirmed; `rag` is derived (Step 4 of scaffolding).

## Outputs

A single risk record at the chosen scope:

```
<scope>/risks/YYYY-MM-DD-slug.md
```

with YAML frontmatter conforming to the [risk record schema](./spec.md#risk-record-schema), `status: open`, and a derived `rag` (GREEN at creation, since `age` is 0).

## Steps

1. **Collect fields.** Elicit title, description, owner(s), escalation threshold, and scope per [Inputs](#inputs-elicited-from-the-contributor). For scope: attempt path inference first and offer to confirm; otherwise prompt for `<type>/<slug>` and offer to list options from `governance/catalogue/scopes.yaml` when that file exists. Derive a `slug` from the title (lowercase, hyphenated) and form the filename `YYYY-MM-DD-slug.md` using today's date.

2. **Suggest the next id.** Read the risk registry — `governance/catalogue/risks.yaml` if the catalogue is split, else `governance/risk-registry.yaml` — and find the highest assigned `R-NNN`. Suggest the next sequential id (e.g. registry's max is `R-014` → suggest `R-015`). **If no registry exists yet, suggest `R-001`.** Confirm the id with the contributor (the author declares it; the suggestion is a convenience), respecting the configured [id prefix](./spec.md#extension-points).

3. **Verify scope membership.** Confirm the contributor is declared at the target scope — present in the scope's `people.md` or DACI. If not, **refuse**: only people with standing at the scope can create a risk there (route them to a feedback entry instead). Likewise verify each named **owner** is declared at the scope; if an owner is not, re-ask or direct the contributor to add them via the scope's consent flow first.

4. **Scaffold the risk record.** Write `<scope>/risks/YYYY-MM-DD-slug.md` with all required fields:
   - `id` — the confirmed `R-NNN`.
   - `title`, `description` — as elicited.
   - `owner` — the named person(s).
   - `status: open`.
   - `escalation_threshold` — the chosen days.
   - `scope` — **required** when `type` is `programme` (written as `programme/root` or the contributor-supplied slug). **Included** for all other types when the contributor confirmed or provided it; omitted only when the contributor explicitly skipped it and the path already implies the scope.
   - `rag` — **derived**: GREEN at creation (`age` is 0, below 50% of the threshold). Recorded as a cached snapshot per [RAG derivation](./spec.md#rag-derivation).
   - `disposition_at` — omitted (no disposition has occurred yet).
   - `disposition_decision_ref` — omitted (only set on disposition).
   - `related` — any links offered, else omitted.

   Create the `risks/` folder at the scope if it does not yet exist (sibling of `decisions/`).

5. **Report.** Show the contributor the file created, the id assigned, and the derived `rag`. State the next steps:
   - run [`/adhere-to risk-at-scope`](../adherence-check/spec.md) to verify conformance of the new record;
   - the risk is now `open` and will escalate to the scope's `feedback.md` once it ages past its `escalation_threshold`;
   - disposition (defer / accept / mitigate / close) follows the [lifecycle](./spec.md#status-lifecycle) — `accepted` will require a full ADR and active governance or project at the scope.

## Refusal conditions

- **The contributor is not declared at the target scope.** Only people present in the scope's `people.md` or DACI can create risks there. The command refuses and points to the feedback-entry route.
- **A named owner is not declared at the scope.** Ownership requires standing; the command re-asks or directs the contributor to the scope's consent flow.
- **The target scope does not exist, or carries neither `people.md` nor DACI.** The command refuses; the scope must exist and identify its people before it tracks risks.
- **A risk file with the same date and slug already exists.** The command flags the collision and does not overwrite.

## Non-goals

- **Does not disposition the risk.** It creates the record at `status: open`; defer/accept/mitigate/close are subsequent edits with their own gates.
- **Does not create the decision record** that an `accepted` or `deferred` transition needs. The contributor records that in `decisions/` per the lifecycle.
- **Does not derive RAG over time.** It sets the initial GREEN snapshot; the risk scanner recomputes RAG and drives escalation on its own cadence.
- **Does not create or update the registry.** The registry is discovery-based — the registry agent walks `risks/` folders and aggregates. This command reads the registry only to suggest the next id.
- **Does not create scopes, `people.md`, DACI, or `feedback.md`.** Those must pre-exist (or are warned about for feedback).

## Related

- [`./spec.md`](./spec.md) — the risk-at-scope capability: schema, RAG derivation, lifecycle, escalation contract.
- [`../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — destination of escalation requests for the risks this command creates.
- [`../governance-at-scope/adopt.md`](../governance-at-scope/adopt.md) — companion scaffolding command; activate governance at the scope when the risk may need an `accepted` disposition.
- [`../adherence-check/spec.md`](../adherence-check/spec.md) — `/adhere-to risk-at-scope` verifies the scaffolded record's conformance.
