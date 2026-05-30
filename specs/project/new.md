# Create a new project

Invoked as: `oos:new project <slug>`
Part of: [`project`](./spec.md) capability.

## Purpose

Elicit the user's intent for a new time-boxed project and scaffold a conformant `projects/<slug>/spec.md` in the adopter's repository.

## Preconditions

- The adopter repository is in **adopt mode**.
- The adopter declares conformance to the `project` capability.
- A `projects/` folder exists at the adopter's repository root.

## Inputs (elicited from the user)

The inputs below are the base set. Before eliciting, the command performs a manifest-overlay step (see "Steps" below) and may add inputs, refine rules, or re-shape the output header based on the adopter's extension. The effective elicitation flow is base + extension, applied together.

1. **Slug.** The project's slug. Used as the folder name under `projects/`. The command asks; it does not infer from the user's prose.
2. **Owner.** Full name and organisational role of the role accountable for the project reaching close (or cancellation). Schema matches `governance-at-scope`.
3. **Objective.** One paragraph stating what the project exists to do. The command prompts the user to be specific; vague objectives trigger a clarifying follow-up ("Who does this help?" or similar).
4. **Close criterion.** One sentence stating how we know the project is done. If the user cannot state one, the command saves the project with `close criterion: TBD` and flags this as a signal the project needs more framing before execution begins.
5. **Hypothesis** (optional). Prompted explicitly: *"Is this an experiment? If so, what is the hypothesis being tested?"* Skipped silently if the project is not experimental.
6. **Success metrics** (optional). Prompted: *"How will you measure success, beyond 'it's closed'?"* Skipped silently if the user has nothing to state.

## Outputs

- `projects/<slug>/spec.md` — conformant with the schema declared in [`spec.md`](./spec.md#schema). Required fields populated: `project`, `status: started`, `opened` (today), `owner`, and an initial `tooling` block recording this `oos:new project` invocation (see [Stamping](#stamping)). Prose body populated with `Objective` and `Close criterion` (required), plus `Hypothesis` and `Success metrics` when elicited. The header representation follows the base spec's YAML frontmatter unless the adopter's extension re-shapes it (see step 0).

## Steps

0. **Load adopter extension.** Read `.open-org-spec/config.yaml`. If the `project` capability declares an `extension:` path, read that file alongside this spec. The extension may:
   - Add required or optional inputs — include them in the elicitation at the natural place (typically after the base input of the same kind).
   - Refine a base rule (e.g., make an optional input required under a stated condition) — apply the refinement when its condition holds.
   - Re-shape the output header representation — use the extension's header form on scaffold, preserving every required field declared in [`spec.md`](./spec.md#schema).
   The base + extension together form the effective elicitation flow for this adopter. If no extension is declared, proceed with the base inputs only.

1. **Identify the slug.** Ask the user. Validate: no existing project at `projects/<slug>/`; if one exists, refuse and surface the existing project.
2. **Elicit owner.** Collect full name and organisational role.
3. **Elicit objective.** Prompt. If the answer is vague or generic, offer to sharpen with a clarifying question.
4. **Elicit close criterion.** Prompt. If the user cannot state one, save as `TBD` and flag — the project is not ready to execute until the close criterion is defined.
5. **Elicit hypothesis (optional).** Ask explicitly. Accept skip.
6. **Elicit success metrics (optional).** Ask explicitly. Accept skip.
7. **Scaffold the file.** Produce `projects/<slug>/spec.md` with the schema filled in. Set `status: started` (the spec is a draft until Gate A passes — see [`spec.md`](./spec.md#gate-a--started--proposed-content-gate)). Include the initial `tooling` block stamping this invocation (see [Stamping](#stamping) below).
8. **Confirm.** Show the user the resulting file and invite edits.

## Stamping

On scaffold, the command writes an initial `tooling` block to the new spec recording first-use of `oos:new project`:

```yaml
tooling:
  oos:new project:
    first: <today's date in YYYY-MM-DD>
    by: <contributor name from `git config user.name`>
```

The block is part of the conformant scaffold; absence is a `gap` finding per [`adherence-check`](../adherence-check/spec.md)'s `Against project` checks. The contributor name is read at run time, not asked — it should match the git identity that will appear in the first commit touching the spec.

## Refusal conditions

- A project with the same slug already exists under `projects/`.
- The adopter is not in adopt mode (creating adopter content does not apply in develop mode).
- The `projects/` folder does not exist at the adopter's repository root.

## Non-goals

- Does not start the project. `status: proposed` is the initial value; moving to `in-progress` is a separate local edit.
- Does not assign work, create tasks, or integrate with issue trackers. Day-to-day task management lives outside the capability.
- Does not add cross-references to other specs (cluster, team, etc.). Users add those when editing the scaffolded spec.
- Does not open a `changes/` folder or go through `capability-lifecycle`. Creating one project is operational work under the standard, not a structural change to the standard; it happens directly.

## Examples

*(To be added: a worked elicitation flowing an example retention initiative through this command to produce a `projects/<slug>/spec.md`.)*
