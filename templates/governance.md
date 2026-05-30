# Governance README template

Copy to `<scope>/governance/README.md` when scaffolding governance at a scope. Conformant with the [governance-at-scope](../specs/governance-at-scope/spec.md) capability.

The frontmatter is authoritative for ownership and DACI (machine-readable). The prose body carries the scope narrative and cross-reference context.

```markdown
---
scope: <repo-wide | module | cross-module | project>
applies_to: <path or scope identifier — "." for repo-wide; module path otherwise>
owner:
  name: <full name>
  role: <organisational role>
daci:
  driver:
    name: <full name or TBD>
    role: <role or TBD>
  approver:
    name: <full name or TBD>
    role: <role or TBD>
  contributors: []          # or: [ { name: <name>, role: <role> } ]
  informed: []              # or: [ { name: <name>, role: <role> } ]
cross_references: []         # or: [ <path to a higher-scope governance folder> ]
---

# Governance

<One or two sentences: what this governance applies to. If this scope has a higher scope whose governance it inherits from, reference it here.>

## What lives here

- <Rules that apply at this scope — routing, conventions, cross-cutting policies.>
- <Cross-references to lower-scope governance once they exist.>

## What doesn't live here

- <Operational specs (what the scope does) — they live in the scope's own README or spec files.>
- <Content produced at this scope (deliverables, artifacts) — they live elsewhere.>

Governance describes how this scope operates, not what it does.
```

## Companion: `decisions/README.md`

The sibling `decisions/` folder (peer to `governance/` at the same scope) gets a simpler, prose-only README. DACI is inherited from the sibling governance folder; it is not re-declared.

```markdown
# Decisions

<Short description of what scope this decisions folder is for.>

Ownership and DACI for decisions at this scope are declared in the sibling [`../governance/`](../governance/) folder; this file describes only the recording convention.

## Convention

One file per decision, named `YYYY-MM-DD-short-title.md`. ADR shape: Context · Decision · Rationale · Consequences · Alternatives · Related.

## Not for

- <List of scopes with their own decisions folders, e.g.: Module-level decisions → the module's own `decisions/` folder.>
```

## Notes

- **Owner-as-default DACI:** at initial adoption, if Driver and Approver aren't separately named, they default to the Owner. Assign them explicitly as the scope's operating model matures.
- **Scope discipline:** DACI participants must have accountability at *this* scope. A module-level contributor does not belong in a repo-wide DACI.
- **Precedence:** higher-scope governance takes precedence. This scope may add rules; it may not contradict rules set by any higher scope.
