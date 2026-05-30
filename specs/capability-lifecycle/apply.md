# Apply a change

Invoked as: `oos:apply <slug>`
Part of: [`capability-lifecycle`](./spec.md) capability.

## Purpose

Apply a proposed change to the repository: move the change's delta contents into their final paths, and update the proposal's status from `proposed` to `applied`.

## Preconditions

- A change folder exists at `changes/<slug>/`.
- The folder contains a `proposal.md` with `status: proposed`.
- The folder contains at least one `<area>-delta/` subfolder with content in final shape.
- The proposal's `mode` matches the repository's current mode.

## Inputs

- **Slug.** The change's slug (the folder name under `changes/`).

## Outputs

- All `<area>-delta/` contents moved to their final paths in the repository.
- `proposal.md` frontmatter updated: `status: applied`.
- All `<area>-delta/` subfolders removed.
- The change folder (now containing `problem.md`, optional `exploration.md`, and the updated `proposal.md`) remains at `changes/<slug>/` pending archive.

## Steps

1. **Load the proposal.** Read `changes/<slug>/proposal.md`. Validate frontmatter: `status` must be `proposed`; `mode` must match the repository's current mode.
2. **Walk the delta folders.** For each file under each `changes/<slug>/<area>-delta/` subfolder, compute its final path by area rule: `specs-delta/<path>` → `specs/<slug>/<path>`; `templates-delta/<path>` → `templates/<path>`; `<area>-delta/<path>` → `<area>/<path>` for any other top-level area.
3. **Check adopt-mode path discipline.** In adopt mode, refuse any target path that falls under `open-org-spec/`.
4. **Check for conflicts.** If any target path already exists, refuse — the proposal must be revised to handle the pre-existing content explicitly (rename, delete, or merge intent). Do not overwrite silently.
5. **Move the delta.** Move each file from its `<area>-delta/` subfolder to its final path.
6. **Update status.** Set the proposal's frontmatter `status` to `applied`.
7. **Remove the empty `<area>-delta/` subfolders.**
8. **Confirm.** Show the adopter the list of moved files and the updated proposal.

## Refusal conditions

- The change folder does not exist.
- The proposal's `status` is not `proposed`.
- The proposal's `mode` does not match the repository's current mode.
- A target path already exists and the delta would overwrite it.
- In adopt mode, any target path falls under `open-org-spec/`.

## Non-goals

- Does not archive the change. Archive is a separate operation; see [`spec.md`](./spec.md#archive-semantics).
- Does not validate the content of the delta against other specs (does not run `adherence-check` automatically). Validation is a separate operation.
- Does not update backlog.md or other information radiators. Those are the contributor's responsibility as part of the proposal pull request.
- Does not bump a version. Versioning is deferred until the standard stabilises.

## Examples

*(To be added: a worked apply of `capability-lifecycle` itself, the first change to use this command.)*
