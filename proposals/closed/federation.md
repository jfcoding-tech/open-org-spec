---
change: federation
status: proposed
opened: 2026-06-11
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: federation capability

## Intent

Add a `federation` capability to the standard. A federation is a repository that orchestrates two or more independent open-org-spec adoptions as git submodules. It introduces five terms to the standard vocabulary — adoption, federation, member, personal member, cascade — and specifies the access model, the information-flow constraint, and the aggregation pattern that any compliant federation must follow.

Every adoption is **standalone-capable**: it works fully when opened directly, without any awareness of or dependency on a federation root. A contributor opens either the adoption directly (standalone mode) or a federation root (federated mode); the adoption behaves identically in both cases. Membership is declared by the federation root in its `.gitmodules`, not by the member — a member repo carries no record of which federations it belongs to and requires no changes to participate in one.

A **personal member** is a distinct member type: an adoption owned by a single contributor and accessible only to them. A contributor adds their personal brain to the federation to bring personal context (career notes, personal development, private work notes) into the same session as the org adoptions they can reach. The same probe-based access model applies: the personal member initialises for its owner and fails silently for everyone else.

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

## Delta

New capability spec at `specs/federation/spec.md`. No changes to existing capability specs.

The spec defines:
- Vocabulary additions: **adoption**, **federation**, **member**, **personal member**, **cascade**
- What a federation root contains: CLAUDE.md with multi-adoption session context, `.gitmodules` for member definitions, optionally `governance/` for cross-member shared artefacts
- Member types: **org member** (access governed by org-level repository permissions, scoped to a subset of contributors) and **personal member** (access scoped to a single contributor; typically hosted in the org's repository space under that contributor's ownership)
- Standalone/federated duality: every adoption must be fully functional when opened directly; federated mode adds cross-member context on top but does not replace standalone capability
- Membership is federation-side: declared in the federation root's `.gitmodules`; the member repo requires no changes to participate; the same member may belong to multiple federation roots simultaneously
- Member contract: each member is an independent adoption with its own governance, observability, and `.open-org-spec/config.yaml`; it has no knowledge of sibling members or the federation root
- Access model: persistence-layer probe (git submodule init; succeed or fail silently); no access-groups config
- Information-flow constraint:
  - Between org members: data flows from more-restricted to less-restricted only, explicitly
  - Involving a personal member: both directions require explicit action — personal → org (explicit cascade) and org → personal (explicit import); neither is a permitted side effect of normal agent work
- Spillage contract (three rules): scope writes to source; probe, don't configure; aggregate ephemerally
- Aggregation pattern: federation-level tools read from each initialised member's artefact store and compose a merged view in memory only; the merged view is never written to either member repo
- Company-hosted personal member caveat: hosting in a company repository grants the organisation administrative access; personal members are for work-adjacent personal context, not content intended to be private from the employer

## Acceptance scenarios

### Member opened standalone is fully functional

Given an adoption that is also a member of a federation root
When a contributor opens the adoption directly (not through the federation root)
Then all tooling, hooks, catchup, and session behaviour work without modification; the contributor experiences no degraded mode and has no awareness of the federation

### Same member belongs to two federation roots simultaneously

Given a contributor working across two organisations, each with its own federation root, both referencing the same adoption as a submodule
When either federation root is initialised
Then the shared member initialises correctly in both contexts; the member repo itself is unchanged; no conflict arises from dual membership

### Cross-org contributor opens a personal federation spanning both organisations

Given a contributor with access to org A's adoption and org B's adoption
And a personal federation root referencing both as submodules
When the contributor opens the personal federation root
Then both org adoptions initialise (subject to credential access); the contributor's session has cross-member context spanning both organisations; each org adoption continues to serve its own contributors in standalone mode unchanged

### Federation root initialises only the members a contributor can reach

Given a federation root with two member submodules: one accessible to the contributor, one not
When the session-start hook runs `git submodule update --init` for each member
Then the accessible member initialises and its catchup data is available; the inaccessible member fails silently and is absent from the session; no error surfaces to the contributor

### Aggregated view is never persisted

Given a federation-level tool that aggregates catchup JSON from two member repos
When the tool composes the merged view for display
Then the merged view is rendered to the terminal only; no merged artefact is written to either member repo or to the federation root

### Information flow is restricted to the explicit cascade direction

Given a contributor working in the federation session with access to both members
When the contributor asks the agent to move content from the more-restricted member to the less-restricted one
Then the agent requires an explicit cascade operation (not a side effect of normal work) and, where a cascade command exists, executes it; it does not propagate content implicitly

### A new access level is added without structural redesign

Given a federation root with two existing member submodules
When a third member with a new access level is introduced
Then it is added as a new submodule entry in `.gitmodules`; no existing member spec, hook, or tooling changes; contributors who lack access to the new member are unaffected

### Personal member initialises only for its owner

Given a federation root with an org member and a personal member submodule belonging to contributor A
When contributor B (who lacks access to the personal member) initialises the federation
Then the org member initialises for contributor B; the personal member fails silently; contributor B's session has no knowledge of the personal member's content

### Personal content does not flow into org repos implicitly

Given a contributor working in a federation session with both an org member and their personal member initialised
When the agent processes a task that touches both members
Then content from the personal member is never written to the org member as a side effect; any transfer from personal to org requires an explicit cascade operation invoked by the contributor

### Org content is imported into personal member explicitly, not as a side effect

Given a contributor who wants to copy an org spec into their personal member for personal annotation
When the contributor asks the agent to do so
Then the agent performs the copy as an explicit import action named as such; it does not copy org content into the personal member as a background operation or incidentally while processing any other task

### Company-hosted personal member: contributor is informed of employer access

Given a contributor adding a personal member hosted in the company's GitHub organisation
When the federation is configured
Then the spec (and any tooling implementing it) makes clear that the company has administrative access to the personal member repo; no assumption of privacy from the employer is warranted
