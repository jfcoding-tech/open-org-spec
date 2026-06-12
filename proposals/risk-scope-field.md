---
change: risk-scope-field
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: explicit scope field on risk records

## Intent

Add an optional `scope` field to the risk record schema. When present, it declares which scope the risk belongs to and determines where escalation entries are routed. For risks in scoped folders (`clusters/<c>/risks/`, `projects/<p>/risks/`, etc.), the field is redundant but confirmatory. For programme-level risks (`risks/` repo root), it is the authoritative routing key — without it, the scanner cannot determine which scope's feedback inbox to write to.

## Rationale

**The risk record's file path is not always a sufficient routing key.** For risks in `clusters/product-development/risks/`, the path tells the scanner: route to `clusters/product-development/feedback.md`. The scope is unambiguous. For risks in `risks/` (repo root — programme-level), the path says only "this is a programme risk". The owner field names a person, but a person can lead multiple scopes. There is no reliable way to infer which scope's feedback inbox the escalation should reach.

**Routing by owner identity breaks when a person holds multiple scopes.** A person who is simultaneously Lead of a cluster and Lead of a function has two valid feedback inboxes. An agent that tries to resolve "what is this person's primary scope?" will either pick arbitrarily, require a tiebreaker rule that becomes increasingly complex, or misroute. The correct answer is: the risk record itself knows which scope it belongs to. The scanner should read that, not infer it.

**Explicit scope declaration makes routing a direct lookup.** When a risk record carries `scope: clusters/product-development`, the scanner reads one field and routes accordingly. No people lookup, no path inference, no tiebreaker. The routing is O(1) per risk record. This also makes the routing contract auditable — anyone reading the risk record can see exactly where escalation will land.

**The field is optional for scoped risks to preserve backwards compatibility.** Risks in `clusters/<c>/risks/` already route correctly from the path; requiring a `scope` field there would force a migration of all existing risk records with no routing benefit. The field is required only when the path is ambiguous — specifically, `risks/` (repo root). Adopters may also declare it on scoped risks for explicitness; the scanner prefers the declared value over the inferred path.

**Validated by a concrete failure.** Programme-level risks in the Busuu second-brain (R-001 through R-018) were all escalated to `governance/feedback.md` addressed to the governance owner, rather than to the risk owners' respective scopes. The root cause: no `scope` field in the records, so the scanner defaulted to the inbox of the scope where the risk file lived (`risks/` → `governance/feedback.md`). Adding `scope` to these records would have made correct routing automatic.

## Delta

Addition to the `risk-at-scope` capability: one new field in the risk record schema.

### New field: `scope`

| Field | Required | Meaning |
|---|---|---|
| `scope` | Required for `risks/` (repo root); optional elsewhere | A scope reference in `<type>/<slug>` format declaring which scope this risk belongs to. Used by the risk scanner to resolve the target feedback inbox via the scope registry. Examples: `cluster/product-development`, `function/revenue`, `project/agentic-coach-phase-3`, `programme`. |

**Scope reference format.** The value follows the `scope-registry` capability's `<type>/<slug>` format. Types: `cluster`, `function`, `project`, `module`, `programme`. The `programme` type has no slug — use `programme` alone for cross-cutting risks that belong to no single scope.

**Routing precedence.** The scanner uses:
1. `scope` field if present — resolve via `governance/catalogue/scopes.yaml` (scope registry), route to the resolved `feedback_inbox`
2. File path inference if `scope` absent — infer from the `risks/` folder's parent path
3. Fall back to `governance/feedback.md` with a `[scope-unresolved]` warning if neither produces a valid inbox

**Validation.** `/adhere-to risk-at-scope` checks:
- Any risk in `risks/` (repo root) that lacks a `scope` field is a conformance gap — `medium` severity.
- Any `scope` value that does not resolve in the scope registry catalogue is a conformance gap — `high` severity.

**Dependency.** The `scope` field resolution requires the `scope-registry` capability to be active (so `governance/catalogue/scopes.yaml` exists). If the scope registry is not active, the scanner falls back to path inference and logs a `[scope-registry-inactive]` warning.

### Impact on the risk scanner

The routing table entry for `risks/` (repo root) changes from:

```
| `risks/` (repo root) | `governance/feedback.md` |
```

to:

```
| `risks/` (repo root) | Resolved from risk.scope via scope registry — required; fall back to governance/feedback.md with warning if absent or unresolvable |
```

All other routing table entries are unchanged.

## Acceptance scenarios

### Programme risk with scope field routes correctly

Given a risk record in `risks/` with `scope: clusters/product-development` and `owner: Yaiza Temprado`
When the risk scanner evaluates it for escalation
Then the escalation entry is written to `clusters/product-development/feedback.md` addressed to Yaiza Temprado
And `governance/feedback.md` receives no entry

### Programme risk without scope field surfaces as conformance gap

Given a risk record in `risks/` with no `scope` field
When `/adhere-to risk-at-scope` runs
Then a `medium` severity gap is reported: "programme risk missing `scope` field"
And the gap is routed to the risk owner's feedback inbox (or governance if owner unresolved)

### Scoped risk without scope field still routes correctly

Given a risk record in `clusters/product-development/risks/` with no `scope` field
When the scanner evaluates it
Then it infers `scope: clusters/product-development` from the file path
And routes to `clusters/product-development/feedback.md` as before
And no conformance gap is raised (field is optional for scoped risks)

### Declared scope takes precedence over path inference

Given a risk record in `clusters/product-development/risks/` with `scope: functions/revenue`
When the scanner evaluates it
Then it routes to `functions/revenue/feedback.md` — the declared scope overrides the path inference

### Invalid scope value surfaces as high-severity gap

Given a risk record with `scope: functions/nonexistent`
When `/adhere-to risk-at-scope` runs
Then a `high` severity gap is reported: "`scope` value does not resolve to an existing feedback.md"

### Owner holding multiple scopes is not a routing problem

Given a risk owned by Yaiza Temprado, who is Lead in both `clusters/product-development` and `clusters/governance`
And the risk record declares `scope: clusters/product-development`
When the scanner evaluates it
Then the escalation routes to `clusters/product-development/feedback.md` addressed to Yaiza
And the fact that Yaiza also leads `clusters/governance` does not affect routing

## Related

- `specs/risk-at-scope/spec.md` — the capability this field extends; risk record schema
- `specs/risk-at-scope/scanner.md` — the tool that consumes the `scope` field for routing
- `proposals/scope-registry.md` — required companion; defines the `<type>/<slug>` format and the `scopes.yaml` catalogue that resolves scope references to feedback inboxes
- `proposals/people-catalogue.md` — parallel catalogue; people entries reference scopes using the same `type/slug` format
