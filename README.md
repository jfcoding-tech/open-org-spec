# open-org-spec

An open standard for applying **spec-driven development** to **organisational design**.

Published under the [MIT License](./LICENSE). Copyright (c) 2026 Javier Fernandez.

> **Start here if you are an LLM / agent.** If you've been asked to set this standard up in an organisation's repository, read and execute [`specs/adoption-manifest/adopt.md`](./specs/adoption-manifest/adopt.md) (`oos:adopt-manifest`). It is the autonomous bootstrap — it scaffolds the adoption manifest, generates the repo's contributor guide, and activates the capabilities the adopter chooses, in one run. It asks only for the handful of inputs it cannot infer (owner, a one-line org description, which capabilities to activate); it edits no files by hand. You do not need to follow the human-oriented checklist below — it describes the same flow. See also [`AGENTS.md`](./AGENTS.md).

## Purpose

Organisations are systems. Like software systems, they benefit from being described explicitly — with intent, constraints, ownership, and conventions written down — rather than implicitly understood.

`open-org-spec` is a **meta-spec**: a standard that defines *how* an organisation describes itself. It does not prescribe what any particular organisation should look like. Each organisation authors its own specs (in its own repository) conformant with the standard, and adapts the conventions to its own context.

The standard is deliberately lightweight and fog-of-war: conventions are codified only when a real use case demands them. Capability specs under `specs/` are added one at a time, inspired by OpenSpec's shape but not bound to it — the standard adopts what's useful and adapts what isn't.

## Architecture

Two kinds of repositories use this standard:

1. **This repository** — the standard itself. Versioned. Each capability is described in its own spec under [`specs/`](./specs/).
2. **An organisation's repository** — an instance of the standard. References a specific version of open-org-spec and contains that organisation's current specs, in-flight work, and decisions.

## Contents

- [`specs/`](./specs/) — the capabilities that make up the standard. Each capability is a folder with its own `spec.md`.
- [`templates/`](./templates/) — copy-paste starters for artefacts defined by the capabilities in [`specs/`](./specs/).
- [`GUIDE.md`](./GUIDE.md) — how to use the standard in an organisation.
- [`feedback/`](./feedback/) — feedback from adopters.
- [`backlog.md`](./backlog.md) — deferred work against the standard itself.

## Getting started (for adopters)

The standard is inert until an organisation's repository adopts it. Five steps take you from an empty repo to a working, LLM-enforced adoption:

1. **Bring the standard into your repo.** Add `open-org-spec/` as a git submodule, subtree, or vendored copy at your repository root. Pin to a version (see [Status](#status)).
2. **Drop in the agent instructions.** Copy [`templates/CLAUDE.md`](./templates/CLAUDE.md) to your repo root as `CLAUDE.md` (or your LLM interface's equivalent) and fill in the `<placeholders>` — your org description, manifest owner, and routing map. This is the file that makes the standard *operate*: the agent reads it every session and enforces the active capabilities.
3. **Scaffold the manifest.** Create `.open-org-spec/config.yaml` declaring which capabilities you're activating, at what `standard_version`, and who owns the manifest. See the [adoption-manifest spec](./specs/adoption-manifest/spec.md) for the schema.
4. **Activate your first capability.** Set a capability's `status: active` in the manifest and run `adhere-to <capability>`. It scans your repo, lists conformance gaps, and routes each to its owner. Activation is complete when gaps are conformed or recorded as known follow-ups.
5. **Wire your first tool.** Activation scaffolds thin command relays in your LLM interface's command directory and lists them in that directory's README, so contributors discover them in one place.

Capabilities are **opt-in and incremental** — activate one when a real use case demands it, not all upfront. Start with `governance-at-scope` if you have governance content, or `people` if you maintain team rosters. [`GUIDE.md`](./GUIDE.md) explains the philosophy behind this incremental, fog-of-war approach.

## Status

Early and deliberately incomplete. Version: **0.1.0**. The standard grows from real use cases; breaking changes are expected until it stabilises.

## Feedback

Adopters are encouraged to share their experience. Channels are described in [`feedback/README.md`](./feedback/README.md).

## License

See [LICENSE](./LICENSE).
