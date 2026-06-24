# Proposal: require --system-prompt in CI agents

**Status:** Applied — see `feat!:` commit, v0.18.0
**Applies to:** `specs/tooling/agent/spec.md` — Contract 3

## Problem

CI agents running with `--dangerously-skip-permissions` read `CLAUDE.md` as their system prompt. `CLAUDE.md` in adopter repos contains contributor-facing instructions (session orientation, catchup commands, contribution conventions) that are irrelevant — and potentially contradictory — for headless agents. The previous workaround was to overwrite `CLAUDE.md` with a minimal stub at the start of each workflow run. This corrupted `CLAUDE.md` for any human session that opened the repo before the file was restored, and created a restore-step dependency that was easy to forget.

## Solution

Pass the agent context stub via `--system-prompt "<stub>"` instead. This flag replaces the CLAUDE.md context for the agent session without touching the file. `CLAUDE.md` is never modified; the stub is injected at the CLI level; no restore step is needed.

## Rationale

The problem and solution were validated in practice in the Busuu/busuu-second-brain adoption before this requirement was added to the standard. The governance-observability and spec-health workflows had both been overwriting `CLAUDE.md` and failing to restore it — on one occasion the stub was committed to the repo and persisted for 6 days before being noticed. Switching to `--system-prompt` eliminated the file dependency entirely.

The rule is simple: `CLAUDE.md` is a shared governance artefact. Agents must not write to it. `--system-prompt` is the correct mechanism for injecting agent-specific context.

## Change

Added one row to the Contract 3 requirements table in `specs/tooling/agent/spec.md`:

| System prompt | `--system-prompt "<agent-stub>"` — never overwrite CLAUDE.md |
