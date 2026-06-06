# Guide — using open-org-spec

This guide introduces the standard at its current state. open-org-spec is deliberately minimal: capabilities are added one at a time, only when a real use case demands them. See [`backlog.md`](./backlog.md) for deferred directions.

> **Just want to adopt it?** The five-step on-ramp — bring in the standard, drop in `CLAUDE.md`, scaffold the manifest, activate a capability, wire a tool — is in [`README.md` § Getting started](./README.md#getting-started-for-adopters). This guide covers the *why* behind that flow.

## Architecture

Two kinds of repository use this standard:

1. **This repository** — the standard itself. Each capability is described in its own spec under [`specs/`](./specs/).
2. **An organisation's repository** — an instance of the standard. References open-org-spec and contains that organisation's current specs, in-flight work, and decisions.

## Currently defined capabilities

- [`governance-at-scope`](./specs/governance-at-scope/spec.md) — how governance content is organised across scopes: where it lives, required frontmatter, precedence rules, and contradiction handling. See [`adopt.md`](./specs/governance-at-scope/adopt.md) for the guided scaffolding flow.

## Capabilities are opt-in

Capabilities describe artefacts and patterns; they do not compel adoption. A repository conforms as long as the artefacts it produces match the schema of the capabilities it adopts. Adopters use only what fits their needs and are free to extend or override the defaults.

`governance-at-scope` illustrates the rule: it shapes governance folders if an adopter has them. It does not require any scope be governed.

## LLM as interface

Changes to a conformant repository are authored through an LLM-assisted interface. The LLM keeps the standard's conventions in working memory on every edit; manual editing tends to produce plausible-looking files with silent gaps.

Every commit includes the trailer:

```
Assisted-by: <tool-id>
```

For example: `Assisted-by: claude-code`. Commits without this trailer are flagged for reviewer confirmation. If a commit was genuinely made manually (urgency, connectivity), say so in the pull request description and consider re-authoring the affected artefact through the LLM afterwards.

The LLM is the enforcer of the standard, not the author of the ideas. The ideas are yours; the structure is the LLM's job.

## Feedback

Adopters are encouraged to share their experience. Open a [GitHub Issue](https://github.com/Busuu/open-org-spec/issues) or email `javier.fdez@gmail.com` with subject `[open-org-spec feedback] <one-line summary>`.
