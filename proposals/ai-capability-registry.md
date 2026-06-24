---
change: ai-capability-registry
status: draft
opened: 2026-06-16
mode: develop
owner:
  name: Javier Fernandez
  role: Standard author
---

# Proposal: AI capability registry and system composition

## Intent

Extend the `capability-lifecycle` spec to introduce `ai-capability` as a named subtype, and define how AI systems are described as compositions of those capabilities. An AI capability is the atomic, reusable AI function — a proven mechanism (mastery inference, knowledge tracing, content evaluation) that has graduated from a project into the organisation's permanent capability layer. An AI system is a product or service that packages one or more AI capabilities together.

This proposal also provides the structural link between `capability-lifecycle` and `aims`: the AI capability registry is the layer from which `aims` derives system risk classifications and generates ISO 42001 impact assessments, without requiring each system to re-document the technical characteristics of the AI functions it uses.

## Rationale

**AI capabilities have properties that general capabilities do not.** The existing `capability-lifecycle` spec treats all capabilities as generic — a process capability ("we know how to run discovery sprints"), a product capability ("we can ship a mobile app"), and an AI capability ("we run a mastery inference model in production") are handled identically. AI capabilities differ in ways that affect governance: they consume and produce data at runtime; they carry risk classifications under the EU AI Act; they require human oversight mechanisms; and they degrade over time as data distributions shift. These are not cosmetic differences. They change what documented information an organisation must maintain and what risk controls it must apply.

**AI systems are understood most clearly as compositions of capabilities, not as monolithic inventory entries.** A flat AI system inventory — one row per deployed product — loses the governance-relevant information. An "Agentic Coach" is not a single AI system: it packages knowledge tracing, knowledge graph querying, personalisation inference, and conversation evaluation. Each constituent capability carries its own risk classification, its own data flows, and its own human oversight mechanism. Understanding the system requires understanding its parts. A composition model surfaces this; a flat inventory conceals it.

**A capability registry eliminates duplication in system-level impact assessments.** Without a shared capability layer, every AI system impact assessment must independently describe the technical characteristics of the AI functions it uses. When the same underlying capability — mastery inference, for example — is used by multiple systems, this produces duplicate and potentially divergent documentation. A capability registry means each AI function is documented once. Impact assessments reference the capability record rather than re-describing it. The standard's principle is that the same fact should live in exactly one place; the capability registry applies this principle to AI governance.

**The graduation lifecycle already exists; AI capabilities need a narrower extension.** `capability-lifecycle` defines when a pattern graduates from a project into the permanent layer. For AI capabilities, graduation must also record data inputs and outputs, the class of model or technique, risk classification, human oversight, and drift detection. These fields are not optional governance overhead — they are the inputs that `aims` uses to assess system risk without duplicating technical documentation across every system that uses the same function.

**This is a generic extension.** The distinction between AI capabilities and general capabilities, the required fields for AI capability graduation, and the system composition model apply across organisations that build or deploy AI systems. None of this is adopter-specific.

## Delta

Extension to `specs/capability-lifecycle/spec.md`.

**New capability subtype: `ai-capability`.**

When a capability's graduation checklist identifies it as using machine learning or statistical inference as part of its core mechanism, it is classified as an `ai-capability`. This classification adds the following required fields to the graduated capability spec:

| Field | Description |
|---|---|
| `input_data` | What data the capability consumes — schema reference or plain-language description |
| `output_data` | What the capability produces |
| `model_type` | The class of model or technique — e.g. `bayesian_knowledge_tracing`, `llm_inference`, `embedding_similarity` |
| `risk_classification` | EU AI Act classification: `minimal` · `limited` · `high` · `unacceptable` |
| `human_oversight` | How a human can review, override, or disable the capability |
| `data_retention` | How long inputs and outputs are retained |
| `drift_detection` | Whether and how distribution drift is monitored — `none`, `manual`, or `automated` |

**New composition field in system specs.**

Any scope spec that describes an AI system — a product or service that uses AI capabilities — may carry a `uses_capabilities` list: the slugs of the `ai-capability` specs it packages. This field is the structural link from which `aims` derives the system's aggregate risk classification (the highest `risk_classification` among its constituent capabilities) without reading project specs.

**Capability registry location.**

AI capabilities graduate to the adopter's designated AI platform scope (e.g. `ai-factory/capabilities/`). The registry is the set of `ai-capability` specs in that folder. No separate registry file is required — the folder is the registry. The `scope-registry` capability indexes the folder alongside other scopes.

## Acceptance scenarios

### AI capability graduates from a project with required fields

Given a project spec that validates a mastery inference model in production
When the model meets the graduation criteria in `capability-lifecycle`
Then a new spec is created at the adopter's capability registry location
And the spec carries all required `ai-capability` fields including `risk_classification` and `human_oversight`
And the project spec links to the graduated capability

### AI system describes its composition

Given a cluster spec for a product that uses mastery inference and knowledge graph querying
When the spec is authored or updated
Then it carries a `uses_capabilities` list referencing both capability slugs
And the aggregate risk classification is derivable from the capability registry without reading any project spec

### aims derives system risk from capability registry

Given an AI system with `uses_capabilities: [mastery-inference, kg-query]`
And both capability specs exist with `risk_classification` fields
When an `aims` impact assessment is authored for the system
Then the assessment references the capability records rather than re-describing the technical characteristics
And the system's aggregate risk classification is the highest `risk_classification` among its constituent capabilities

### Capability reused across two systems without duplication

Given a `mastery-inference` capability spec in the registry
And two system specs that both list `mastery-inference` in their `uses_capabilities`
When `/adhere-to aims` is run
Then both systems' impact assessments reference the single capability record
And the `input_data`, `output_data`, and `model_type` fields are not duplicated in either system's documentation

### Adopter with no AI capabilities active passes without error

Given an adopter with `capability-lifecycle` active but no graduated `ai-capability` specs
When `/adhere-to capability-lifecycle` is run
Then no error is raised for the absence of `ai-capability` specs
And the `ai-capability` subtype is treated as optional until an AI capability is graduated

## Related

- `specs/capability-lifecycle/spec.md` — base spec this extends
- `proposals/aims.md` — the AIMS capability that consumes `ai-capability` fields for ISO 42001 conformance
- `specs/risk-at-scope/spec.md` — risk assessment for high-risk AI capabilities
- `specs/people/spec.md` — named ownership required for each graduated capability
