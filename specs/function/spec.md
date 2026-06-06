# Function

**Owner:** Javier Fernandez
**Status:** Active

A structural type for cross-cutting business capabilities that operate across clusters — not a line of business, not shared services, not infrastructure.

---

## Definition

A **function** is an atemporal organisational unit that:

- Operates **across** clusters, setting frameworks, guardrails, and commercial models that clusters execute within.
- Has **no close date** — its spec is updated when reality changes, never "finished".
- Is **not** a cluster (a function does not own a line-of-business outcome or a user-facing product).
- Is **not** a shared-services module (a function does not provide reusable tooling or platform capabilities to other units).
- Is **not** infrastructure (a function does not own platform, cloud, or developer tooling).

Examples of the function type: Revenue Operations, Marketing, Finance, Legal, People.

The distinction from a cluster: clusters *produce* business outcomes. Functions *set the rules* within which clusters operate on cross-cutting concerns (pricing, spend guardrails, compliance, incentives, forecasting).

---

## What belongs in a function folder

The same test as for clusters: **if this folder were deleted, would the org forget how this function works?** If yes, it belongs here.

Concretely:

- **Atemporal specs** — mandate, ownership boundaries, cross-functional interfaces. Describes what the function owns, what adjacent functions own, and how handoffs work.
- **Decisions** — in a `decisions/` subfolder, dated `YYYY-MM-DD-short-title.md`. Function-level decisions about the function's own operating model, ownership boundaries, or policy choices.
- **Feedback inbox** — `feedback.md` for cross-contributor observations and nudges.

What does **not** belong here:

- Deliverables (models, reports, forecasts, presentations) — these live in their system of record (Drive, Confluence, Notion) and are linked from the spec.
- Project-level decisions — time-boxed initiatives that exercise the function's frameworks belong in `projects/`.
- Cluster content — if content belongs to a specific cluster's delivery, it lives in that cluster's folder.

---

## Governance requirements

Every function folder must satisfy:

1. **Named owner** — an individual accountable for the spec's accuracy. Named in the spec frontmatter and in the folder's `README.md`.
2. **`governance-at-scope` active** — the function owner declares a DACI, names the scope owner, and ensures decisions at this scope follow the governance-at-scope pattern defined in [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md).
3. **Status** — every spec carries `status: Active | Draft | Deprecated`.

The function owner is responsible for:
- Keeping the mandate and boundary descriptions current.
- Ensuring decisions that affect the function's scope are recorded in `decisions/`.
- Responding to feedback entries in `feedback.md`.

---

## Activation

Adding a new function folder requires an ADR in the adopter's decisions record before the folder lands. The ADR must:

- Name the function and its owner.
- Explain why no existing structural type (cluster, shared-services module, infrastructure) fits.
- Reference this spec.

The adopter's governance owner must acknowledge any new top-level folder via an ADR per their governance rules.

---

## Structural position

A function folder sits at the **repo root**, alongside the adopter's other top-level scopes (lines of business, shared services, infrastructure, project collections, etc.).

Folder name convention: `<function-slug>/` (lowercase, hyphenated). Example: `revenue-function/`, `marketing/`, `finance/`.

---

## Folder structure (canonical)

```
<function-slug>/
├── README.md          # owner, status, one-line description
├── spec.md            # atemporal spec — mandate, ownership boundaries, interfaces
├── decisions/
│   └── README.md      # decision record convention for this scope
└── feedback.md        # cross-contributor observations; primary addressee: function owner
```

Additional files or sub-specs may be added by the function owner as the scope grows, without a new ADR — the ADR gates the top-level folder creation, not its internal organisation.

---

## Related

- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — governance-at-scope capability, required for every function.
