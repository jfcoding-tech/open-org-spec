# Federation

A capability of open-org-spec describing how multiple independent adoptions of the standard relate to one another: how a repository orchestrates several adoptions as git submodules, how access is determined, how information is allowed to flow across access boundaries, and how cross-member views are composed without ever persisting content across those boundaries.

**Status:** Active

**Owner:** Javier Fernandez

## Purpose

A single adoption models one organisation, or one access level, well. It does not model an organisation that needs **several access levels** — public, executive-only, HR-only, board-only — where some content is confidential to a subset of contributors. The usual ad-hoc response is to nest the restricted content inside the open repository (a symlink or subdirectory under tighter controls). That nesting creates implicit cross-boundary reads, does not extend past two levels without redesign, and leaks the very existence of the restricted content to tooling that has to know about it.

This capability codifies the alternative so adopters don't re-derive it: **sibling repositories, not parent-child.** Each adoption is a complete, independently governed instance of the standard that knows nothing about its siblings. A **federation root** — itself an adoption — references them as git submodules and adds cross-member session context on top. The model extends to any number of access levels without restructuring, keeps each adoption fully functional on its own, and makes the access boundary a hard correctness property rather than a convention.

It is distinct from [`governance-at-scope`](../governance-at-scope/spec.md): governance-at-scope answers "who decides *within* one adoption?"; federation answers "how do *several* adoptions relate, and what may cross between them?"

## Vocabulary

| Term | Meaning |
|---|---|
| **adoption** | A single open-org-spec repository — one complete, independently governed instance of the standard. |
| **federation** | A repository that orchestrates two or more adoptions as git submodules, providing cross-member session context and (optionally) shared artefacts. The federation root is itself an adoption. |
| **member** | An adoption that belongs to a federation. A member is referenced by the federation root's `.gitmodules`; it carries no record of the federations that include it. |
| **personal member** | A member whose access is scoped to a single contributor — that contributor's individually scoped "brain," typically hosted in the organisation's repository space under their ownership. |
| **cascade** | An explicit, deliberate operation that moves content from a more-restricted member to a less-restricted one (or, for a personal member, in either direction). A cascade is never a side effect of normal work. |

## Pattern

### Federation root structure

A federation root is an adoption like any other, plus three things that make it a federation:

- **`CLAUDE.md`** (or the equivalent agent-instructions file for the interface) carrying **multi-adoption session context** — the cross-member working model, the cascade rules, the spillage contract, and which members the session may compose.
- **`.gitmodules`** defining the members as git submodules. This is the sole declaration of membership.
- Optionally, a **`governance/`** folder holding cross-member shared artefacts — for example a canonical contributor registry that every member would otherwise duplicate. Cross-member shared artefacts are the only governance content that belongs at the federation root; per-member governance stays in each member.

The federation root is not infrastructure bolted onto the standard — it *is* the standard, applied to the relationship between adoptions.

### Member contract and standalone capability

Each member is an **independent adoption** with its own governance, observability, tooling, hooks, and `.open-org-spec/config.yaml`. A member has **no knowledge of its sibling members or of any federation root**.

**Standalone capability is a hard requirement.** A member must work fully when opened directly, with no awareness of or dependency on a federation root. All of its tooling, hooks, catchup, and session behaviour must be self-sufficient. A member that degrades when opened outside a federation is **not conformant.**

This requirement is what makes federation opt-in for contributors. An individual who needs only one adoption opens it directly and loses nothing. A contributor with access to several adoptions opens a federation root and gains cross-member context on top. The same binary choice holds across organisational boundaries: a contributor working across two organisations can keep a personal federation root spanning adoptions from both, while each adoption continues to serve its own contributors in standalone mode, unchanged.

### Membership is federation-side

Membership is declared **by the federation root, not by the member.** The federation root adds an entry to its `.gitmodules`; the member repo requires **no changes** to participate.

Two consequences follow. First, the **same member may belong to multiple federation roots simultaneously** — an org-level federation root and a contributor's personal cross-org federation root can both reference the same member with no conflict, because the member carries no membership record to conflict over. Second, **adding a member costs the member nothing**: it does not know it has been added.

### Member types

| Type | Access | Hosting |
|---|---|---|
| **org member** | Governed by org-level repository permissions; scoped to a subset of contributors (e.g. everyone, or executive-only, or HR-only). | The organisation's repository space. |
| **personal member** | Scoped to a single contributor. | Typically the organisation's repository space, under that contributor's ownership (see the company-hosted caveat below). |

Org members form a graded hierarchy of access levels (more-restricted to less-restricted). A personal member sits **outside** that linear hierarchy — it is a separate, individually scoped dimension, not "more restricted than the org" in the way executive content is more restricted than public content.

### Access model (probe-based)

Access is determined by the **persistence layer, not a second config file.** There is no `access-groups.yaml` declaring who may reach which member — that would duplicate the access control the repository host already enforces and create a second source of truth that can drift (and which could itself be read by contributors who lack the access it describes).

Instead, the federation **probes**. At session start (or on demand), for each member in `.gitmodules`:

```
git submodule update --init <member>   # succeed, or fail silently
```

A member the contributor's credentials can reach initialises and joins the session. A member they cannot reach fails silently and is simply absent — no error surfaces. **What a contributor can reach is determined by their credentials, not by a config file.**

A noted, accepted limitation: anyone who can read the federation root's `.gitmodules` can see that a member *exists* even if they cannot clone it. Where the mere existence of a member is itself sensitive, the federation root carrying that entry must be access-controlled accordingly.

### Information-flow constraint

**Between org members.** Data flows from **more-restricted to less-restricted only**, and only by an **explicit cascade** — never as a side effect of normal work. Content never flows from a less-restricted member into a more-restricted one's account of itself by accident, and never flows the wrong way (less- to more-restricted is not the concern; the concern is restricted content leaking *down* implicitly). A more-restricted member's content reaching a less-restricted member must be a deliberate, named cascade operation.

**Involving a personal member.** Because a personal member is individually scoped rather than a point on the org hierarchy, **both directions require explicit action**:

- **personal → org** requires an explicit cascade, for the same reason executive-to-public does: the personal member may hold individually sensitive material not appropriate for the org.
- **org → personal** requires an explicit **import**: the agent must not silently copy org content into a contributor's personal member as a side effect of session work, since that content may later be visible to unexpected parties if the personal member's access ever broadens.

In both directions, explicit, contributor-invoked action is the rule. Implicit propagation is never permitted.

### Spillage contract

Any feature that operates across members must honour three rules. These are correctness requirements, not implementation preferences.

1. **Scope writes to source.** An agent writes its output only to the member it analysed. Analysis of member A never produces a write to member B or to the federation root.
2. **Probe, don't configure.** Access is determined by what exists on disk after the init probe, not by a config file — a config file enumerating access could itself spill the information it controls.
3. **Aggregate ephemerally.** Merged views exist only at render time, in memory, for the session that requested them. They are never persisted to any member repo or to the federation root.

### Aggregation pattern

A federation-level tool that needs a cross-member view (a merged catchup, a combined dashboard) reads from **each initialised member's own artefact store** and composes the merged view **in memory only**. It presents that view to the requesting session and writes nothing back.

The merged view must never be persisted — even to a "neutral" location. A persisted merged artefact would carry content determined by the **most-restricted member it includes**, while inheriting the access controls of the location it was written to. The two need not match, and when they don't, the artefact is a spillage. Ephemeral aggregation closes that gap by construction.

### Company-hosted personal member caveat

Hosting a personal member in a company repository is convenient — the contributor needs no personal hosting credentials, and access provisioning follows the same org tooling. But it is **not private from the employer**: hosting in the company's repository space grants the organisation administrative access regardless of contributor-level permissions.

Company-hosted personal members are therefore appropriate for **work-adjacent personal context** — career-development notes, learning journals, work reflections. Content a contributor intends to keep genuinely private from their employer must be hosted **elsewhere, outside the company's repository space.** Tooling implementing this capability must make the employer-access reality clear when a company-hosted personal member is configured; no assumption of privacy from the employer is warranted.

## What is not prescribed

- **The hosting service.** The capability assumes a persistence layer that enforces per-repository access (private repositories with permissions) and supports submodules. It does not require GitHub specifically.
- **The number or naming of access levels.** Two, three, or more org members at graded access levels are all conformant. Adopters choose the levels their organisation needs.
- **Whether a federation root carries a `governance/` folder.** Shared cross-member artefacts are optional; a federation root with only `CLAUDE.md` and `.gitmodules` is conformant.
- **The mechanics of the cascade and import operations.** The capability requires that cross-boundary movement be explicit and never a side effect; it does not prescribe a particular command, redaction step, or transformation. Adopters define their own cascade/import tooling.
- **Credential provisioning.** How contributors obtain access to a member (deploy keys, SSO, direct grants) is an adopter operational choice, invisible to the probe-based model.
- **Whether any given adoption is ever federated.** Federation is opt-in. An adoption that is never added to any federation root is fully conformant on its own; the standalone requirement guarantees it loses nothing.

## Rationale

**A single adoption cannot model an organisation with multiple access levels.** As an organisation grows, some content becomes confidential to a subset of contributors (executive-only, HR-only, board-only). The natural response is to create a second repository for that content, with tighter access controls. Without a standard model for how those repositories relate, each organisation re-derives the relationship ad hoc — often by nesting the restricted repo inside the open one (as a symlink or subdirectory), which creates spillage risk and is not extensible beyond two levels.

**Nesting creates the problems it was meant to solve.** When a restricted repo is symlinked or nested inside a less-restricted one, any agent or tool operating on the outer repo can reference paths in the inner one, producing implicit cross-boundary reads. Adding a third access level compounds the problem — the structure must be redesigned rather than extended. And tooling that knows about the symlink is implicitly aware of the inner repo's existence, which is itself information that may need to be controlled.

**The right model is sibling repos, not parent-child.** Each adoption is a complete, independently governed instance of the standard. Adoptions do not know about each other. A federation root — itself an open-org-spec adoption — references them as git submodules and provides the cross-member session context, tooling, and (optionally) canonical shared artefacts such as a contributor registry. This is extensible to any number of access levels without redesigning the structure.

**Standalone capability is a hard requirement of the member contract.** A member must work fully when opened directly — all tooling, hooks, and session behaviour must be self-sufficient. A member that degrades without a federation root is not conformant. This requirement is what makes federation opt-in for contributors: an IC who only needs one adoption opens it directly and loses nothing; a contributor with access to multiple adoptions opens a federation root and gains cross-member context on top. The same binary choice applies across organisational boundaries: a contributor working across two organisations can maintain a personal federation root that includes adoptions from both, while each adoption continues to serve its own contributors in standalone mode unchanged.

**Membership is declared by the federation root, not by the member.** A member repo carries no record of which federations include it. This decoupling means the same adoption can participate in multiple federation roots simultaneously — an org-level federation root and a contributor's personal cross-org federation root can both reference the same member without conflict. It also means adding a member to a federation requires no changes to the member repo: the federation root adds an entry to its `.gitmodules`, and the member is unaware.

**Access should be determined by the persistence layer, not a second config file.** Adding an `access-groups.yaml` to declare which contributors can access which members would duplicate the access control already enforced by the repository hosting service (GitHub private repository permissions, for example), creating two sources of truth that can diverge. The correct model is to probe: attempt to initialise each submodule, and proceed with the ones that succeed. What a contributor can reach is determined by their credentials, not by a config file that could itself be read by contributors who lack the access it describes.

**Merged views must never persist across the access boundary.** When a federation-level tool aggregates data from multiple members, it must compose the aggregated view in memory and present it only to the session that requested it. Persisting the aggregated view — even in a neutral location — would create an artefact whose content is determined by the most-restricted member it includes, but whose access controls are those of the location it was written to. Ephemeral aggregation is not an implementation detail; it is a correctness requirement.

**Personal members require a two-directional cascade rule.** Org-scoped members follow a one-directional rule: content flows from more-restricted to less-restricted, explicitly, never implicitly. Personal members sit outside this linear hierarchy — they are not "more restricted than the org" in the same sense that ELT is more restricted than the public. A contributor's personal brain is a separate dimension: individually scoped. This makes both directions sensitive. Personal → org requires explicit cascade for the same reason ELT → public does: content may contain individually sensitive material not appropriate for the org. Org → personal also requires an explicit import: the agent must not silently copy org content into a contributor's personal member as a side effect of session work, since that content may later be visible to unexpected parties if the personal member's access ever broadens. In both directions, explicit action is the rule.

**Company-hosted personal members come with an employer-access caveat.** A personal member hosted in a company repository is subject to the hosting organisation's administrative access rights, regardless of contributor-level permissions. Hosting in the company's repository space is convenient — contributors do not need personal GitHub credentials, access provisioning follows the same org tooling — but it is not private from the employer. Personal members hosted in the company's repo are appropriate for work-adjacent personal context (career development notes, learning journals, work reflections). Content a contributor intends to keep genuinely private from their employer must be hosted elsewhere, outside the company's repository space.

## Related

- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — governs decision authority *within* a single adoption; federation governs how *several* adoptions relate. A federation root carries its own governance-at-scope for cross-member shared artefacts.
- [`../adoption-manifest/spec.md`](../adoption-manifest/spec.md) — every member, and the federation root itself, is an adoption declaring its capabilities in `.open-org-spec/config.yaml`. Federation does not change the manifest contract; it composes adoptions that each carry their own.
