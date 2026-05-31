# Templates

Copy-paste starters for the artefacts an adopter creates. These are reference
implementations: deliberately **interface-agnostic**. The standard never prescribes a
particular LLM interface, so every template uses placeholders (`<command-directory>`,
`<command-name>`, paths) that you resolve to whatever your interface reads. Claude Code
is named only as a worked example of how the placeholders map.

## What's here

| Template | Copy to | Purpose |
|----------|---------|---------|
| [`CLAUDE.md`](./CLAUDE.md) | your interface's agent-instructions path — `CLAUDE.md` (Claude Code), `.github/copilot-instructions.md` (GitHub Copilot), `.cursor/rules/` (Cursor) | makes the standard *operate* — the agent reads the manifest and enforces active capabilities |
| [`config.yaml`](./config.yaml) | `.open-org-spec/config.yaml` | the adoption manifest — which capabilities are active, at what version, with what extensions |
| [`command-relay.md`](./command-relay.md) | your interface's command directory | a thin relay that points an invocation at its canonical spec |
| [`governance.md`](./governance.md) | a scope's `governance/README.md` | governance folder scaffold (used by `governance-at-scope`) |
| [`problem.md`](./problem.md) · [`proposal.md`](./proposal.md) · [`feedback.md`](./feedback.md) | per the capability that defines them | artefact starters |

## Wiring a tool (any interface)

The standard's tools keep their logic in a **canonical spec** (e.g.
`open-org-spec/specs/tooling/catchup/spec.md`). What an adopter adds is a thin **relay**
in whatever location their LLM interface resolves invocations from — its "command
directory". The relay does one thing: tell the agent to read the canonical spec and
execute it. Use [`command-relay.md`](./command-relay.md) as the starter.

1. **Pick the command location your interface reads.** Claude Code → `.claude/commands/<name>.md`
   relay files; GitHub Copilot → `.github/prompts/<name>.prompt.md` prompt files (invoked as
   `/<name>`); other interfaces → wherever that interface resolves invocations. Some interfaces
   (e.g. Cursor) have **no command mechanism** — there, a command is invoked by pointing the
   agent at its canonical spec, and the commands README records that instead of a relay path.
   See the interface table in [`../specs/adoption-manifest/adopt.md`](../specs/adoption-manifest/adopt.md#interface-conventions).
2. **Drop in one relay per command** a capability declares (e.g. `adopt`, `new`,
   `extend`, `catchup`, `adhere-to`). Fill the placeholders from the canonical spec.
3. **List every relay in the command directory's `README.md`** — the ownership index.
   One surface where a contributor sees every command, its owner, and its canonical
   spec. Adding a row here is what makes a command *discoverable*.

When a capability is activated, the `adhere-to` flow scaffolds these relays and the
README rows for you; the templates above are for doing it by hand or for interfaces
without that automation.

## Session-start orientation (optional, any interface)

Some tools are meant to run at the start of every session (e.g. `catchup`, which shows
a returning contributor what changed). If your interface supports a **session-start
hook**, wire it to invoke that command on launch. For Claude Code this is a `SessionStart`
hook in `.claude/settings.json`; other interfaces use their own mechanism. The standard
treats this as an adopter convenience, not a requirement — the command works the same
whether it is invoked by a hook or typed by hand.
