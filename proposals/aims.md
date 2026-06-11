---
change: aims
status: proposed
opened: 2026-06-12
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: AI Management System (AIMS) capability

## Intent

Add an `aims` capability to the standard. When activated alongside the required peer capabilities (`governance-at-scope`, `people`, `risk-at-scope`, `feedback-inbox`), `aims` makes an open-org-spec adoption a conformant documented information layer for ISO/IEC 42001:2023 — the international standard for AI Management Systems.

The capability does two things: it declares the formal mapping between open-org-spec's existing artifacts and ISO 42001's clause-by-clause requirements; and it introduces three artifact types that cover the gaps the existing capabilities do not — an AI policy document, an AI system inventory, and per-system impact assessments. An adopter who activates `aims` and passes `/adhere-to aims` has satisfied the documented information requirements of ISO 42001 as a side-effect of operating under the standard.

## Rationale

**ISO 42001 is a governance standard, and open-org-spec is a governance framework.** ISO/IEC 42001:2023 follows the Annex SL high-level structure shared with ISO 27001 and ISO 9001. Its requirements — clauses 4 through 10 — are fundamentally requirements for documented governance: declared scope, assigned accountability, assessed risks, controlled documented information, measured performance, and closed corrective action loops. These are not AI-specific requirements that demand a separate system; they are the same governance requirements that any well-run organisation satisfies through its operating model. Open-org-spec models exactly these things.

**A significant portion of the standard's requirements is already satisfied by existing capabilities.** The mapping is not incidental:

- `governance-at-scope` — satisfies Clause 5 (leadership, roles, accountability, DACI), Clause 9 (management review decisions), and Clause 10 (corrective action records in `decisions/`)
- `people` — satisfies Clause 5 (roles and responsibilities assigned and named), Clause 7 (competence records per scope)
- `risk-at-scope` — satisfies Clause 6 (risk and opportunity assessment process with lifecycle tracking and escalation)
- `feedback-inbox` — satisfies Clause 10 (nonconformity identification and routing)
- The repo itself — satisfies Clause 7 (documented information: every spec, decision, risk, and feedback entry is version-controlled, dated, and attributed)
- `observability` — satisfies Clause 9 (monitoring and measurement of system performance)

**The gap is thin and well-defined.** Three artifact types are missing from the existing capabilities:

1. **AI policy** — ISO 42001 Clause 5 requires a formal, approved AI policy document declaring the organisation's AI governance principles, objectives, and commitments. No existing capability defines this artifact.
2. **AI system inventory** — Clause 8 requires a catalogue of in-scope AI systems with their risk classification. This is a distinct artifact from a project spec: it is a standing record of what the organisation deploys, not a time-boxed development initiative.
3. **Impact assessment** — Clause 8 requires an impact assessment for each in-scope AI system before deployment and at significant change points. No existing capability defines this artifact or its required fields.

**Orgs pursuing ISO 42001 currently build this governance infrastructure from scratch.** Without this capability, an organisation attempting certification must design and implement a governance framework, risk management process, documented information system, accountability structure, and monitoring capability independently — all of which open-org-spec already provides. The `aims` capability removes this duplication: the governance infrastructure is the certification evidence.

**The capability is generic.** ISO 42001 applies to any organisation that develops, provides, or uses AI systems. The three gap artifact types — AI policy, system inventory, impact assessment — are not adopter-specific. The mapping between existing open-org-spec capabilities and ISO 42001 clauses is structural and holds across organisations. The `aims` capability belongs in the standard, not in an adopter extension.

**ISO 42001 and this standard share a structural philosophy.** Both are built on the principle that governance should be documented, owned, measurable, and continuously improved. An adopter who has internalized open-org-spec's operating model has also internalized the ISO 42001 operating model. The certification is, in effect, a third-party validation of the governance practice the standard already requires.

## Delta

New capability spec at `specs/aims/spec.md`. No changes to existing capability specs.

The spec defines:

**Capability mapping.** A formal, clause-by-clause mapping between ISO 42001:2023 requirements and the open-org-spec artifacts that satisfy them. The mapping declares which existing capabilities are required peer dependencies and what each one covers.

**Required peer capabilities.** `aims` requires `governance-at-scope`, `people`, `risk-at-scope`, and `feedback-inbox` to be active. `/adhere-to aims` checks that all four are present before assessing AIMS-specific conformance.

**Three new artifact types:**

1. **AI policy** (`<scope>/ai-policy.md`) — a governed document declaring the organisation's AI principles, objectives, commitments, and governance scope. Required frontmatter: `owner`, `status`, `approved_by`, `approved_at`, `review`. Body sections: scope of the AIMS, AI principles, governance commitments, roles summary, review cadence.

2. **AI system inventory** (`<scope>/ai-system-inventory.md`) — a standing catalogue of all AI systems in scope for the AIMS. Each entry carries: system name, description, owner, risk classification (`minimal` · `limited` · `high` · `unacceptable` per EU AI Act alignment), deployment status, impact assessment reference, and last reviewed date.

3. **Impact assessment** (`<scope>/impact-assessments/<system-slug>.md`) — a per-system record assessing the impact of an AI system before deployment and at significant change. Required fields: system, owner, assessment date, risk classification, affected parties, potential harms, likelihood, mitigations, human oversight mechanisms, residual risk, and approval record.

**Conformance checks for `/adhere-to aims`.** The tool checks:
- AI policy exists, is approved, and carries required sections
- AI system inventory exists and every listed system has a corresponding impact assessment
- Every in-scope AI system has a named owner in `people.md` at the governing scope
- Risk records exist for high-risk and unacceptable-risk systems
- Management review decisions are present in `decisions/` at the AIMS governance scope
- All four peer capabilities are active

**AIMS readiness report.** `/adhere-to aims` produces a readiness summary mapping each ISO 42001 clause to its conformance status: `satisfied` (covered by existing capabilities and artifacts), `partial` (artifact exists but incomplete), or `absent` (artifact missing).

## Acceptance scenarios

### Adopter with all peer capabilities active passes readiness check

Given an adopter with `governance-at-scope`, `people`, `risk-at-scope`, `feedback-inbox`, and `aims` all active
And an AI policy, an AI system inventory, and impact assessments for all listed systems present
When `/adhere-to aims` is run
Then the readiness report shows `satisfied` for clauses 5, 6, 7, 9, 10
And `satisfied` or `partial` for clause 8 depending on impact assessment completeness
And no `absent` findings for any clause

### Missing AI policy surfaces as critical gap

Given an adopter with `aims` active but no AI policy document
When `/adhere-to aims` is run
Then a `critical` gap is reported for Clause 5 (leadership — AI policy absent)
And a feedback entry is routed to the AIMS owner's inbox

### AI system in inventory without impact assessment surfaces as gap

Given an AI system inventory listing a system with risk classification `high`
And no impact assessment file for that system
When `/adhere-to aims` is run
Then a `critical` gap is reported for Clause 8 (operation — impact assessment absent for high-risk system)

### Adopter can demonstrate documented information to an auditor

Given an adopter with `aims` fully conformant
When an ISO 42001 certification auditor requests documented information evidence
Then the adopter can point to: the repo as the version-controlled documented information system; `governance/README.md` for leadership and accountability; `risks/` for risk assessment; `people.md` for roles and competence; `feedback.md` + `decisions/` for nonconformity and corrective action; `ai-policy.md` for AI policy; `ai-system-inventory.md` for system scope; `impact-assessments/` for Clause 8 evidence

### `/adhere-to aims` checks peer capability dependencies first

Given an adopter with `aims` active but `risk-at-scope` inactive
When `/adhere-to aims` is run
Then the tool reports that `risk-at-scope` is a required peer capability and is not active
And halts further conformance checking until the dependency is resolved

## Related

- `specs/governance-at-scope/spec.md` — required peer capability; Clause 5 and 10 coverage
- `specs/people/spec.md` — required peer capability; Clause 5 and 7 coverage
- `specs/risk-at-scope/spec.md` — required peer capability; Clause 6 coverage
- `specs/feedback-inbox/spec.md` — required peer capability; Clause 10 coverage
- `specs/observability/spec.md` — optional peer; strengthens Clause 9 coverage when active
