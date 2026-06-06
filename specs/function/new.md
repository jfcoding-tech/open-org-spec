# New function (command)

Invoked as: `oos:new-function`
Part of: [`function`](./spec.md) capability.

## Purpose

Scaffold a conformant function folder at the repo root **after** the ADR approving it has been committed. The [`function` spec](./spec.md#activation) requires an ADR in the adopter's decisions record before a new function folder lands; this command runs once that ADR exists, reads its fields (or accepts them as inputs), and produces the canonical folder structure conforming to [`spec.md`](./spec.md#folder-structure-canonical).

This is a post-ADR scaffolding command. It does not approve the function — the ADR does that. It turns an approved decision into the folder structure on disk.

## Preconditions

- The adopter's repository is conformant with open-org-spec, or is in the process of adopting conformance.
- An ADR approving the new function folder has been committed to the adopter's decisions record. The command verifies this (see Step 2); it does not create the ADR.
- The function does not already exist at the repo root. The command does not overwrite an existing function folder.

## Inputs (elicited, or read from the ADR)

1. **Function slug.** Lowercase, hyphenated (e.g. `revenue-function`, `marketing`, `finance`). Becomes the repo-root folder name.
2. **Owner name.** The individual accountable for the spec's accuracy.
3. **Owner role.** The role under which they hold accountability for this function.
4. **One-line mandate.** A single sentence describing what cross-cutting concern this function sets the rules for.

The command prefers to read these from the approving ADR. If the ADR names them, it confirms the values with the adopter rather than re-asking. If any field is absent from the ADR, the command elicits it.

## Outputs

A function folder at the repo root, per the canonical structure in [`spec.md`](./spec.md#folder-structure-canonical):

```
<function-slug>/
├── README.md          # owner, status: active, one-line description
├── spec.md            # YAML frontmatter (owner name+role, status: active) + mandate, owned areas, related
├── decisions/
│   └── README.md      # ADR convention for this scope
└── feedback.md        # cross-contributor observations header; primary addressee: function owner
```

All files use **YAML frontmatter** (function-instance specs use YAML frontmatter, per the decision recorded for this scope and as modelled by [`spec.md`](./spec.md) itself).

## Steps

1. **Collect fields.** Read the approving ADR if its path is provided or discoverable; extract slug, owner name, owner role, and one-line mandate. Confirm read values with the adopter. Elicit any field the ADR does not supply.

2. **Verify the ADR exists and is committed.** The [`function` spec](./spec.md#activation) gates folder creation on a committed ADR. Locate the ADR in the adopter's decisions record and confirm it is committed (not only in the working tree). The ADR must name the function and its owner, explain why no existing structural type (cluster, shared-services module, infrastructure) fits, and reference the function spec. If no committed ADR is found, **refuse** and direct the adopter to record and commit the ADR first.

3. **Check for collision.** Confirm `<function-slug>/` does not already exist at the repo root. If it does, **refuse** and do not overwrite — defer to an edit flow (out of scope for this command).

4. **Scaffold `<function-slug>/README.md`.** YAML frontmatter with the owner (name + role) and `status: active`, then a one-line description derived from the mandate.

5. **Scaffold `<function-slug>/spec.md`.** YAML frontmatter:

   ```yaml
   ---
   owner:
     name: <owner name>
     role: <owner role>
   status: active
   ---
   ```

   Body: the one-line mandate, an "owned areas" section (ownership boundaries — what this function owns and what adjacent functions own), and a "Related" section linking [`../function/spec.md`](./spec.md) and the [`governance-at-scope` spec](../governance-at-scope/spec.md) (required for every function).

6. **Scaffold `<function-slug>/decisions/README.md`.** The ADR convention for this scope: decisions dated `YYYY-MM-DD-short-title.md`, recording function-level decisions about the operating model, ownership boundaries, or policy choices. Note DACI inheritance from the function's `governance-at-scope` declaration.

7. **Scaffold `<function-slug>/feedback.md`.** A cross-contributor observations header naming the function owner as the primary addressee.

8. **Report.** Show the adopter the folder and files created, and remind them to activate `governance-at-scope` at this scope (a function governance requirement per [`spec.md`](./spec.md#governance-requirements)).

## Refusal conditions

- No committed ADR approving the function folder is found. The command refuses; the ADR gates folder creation.
- A folder named `<function-slug>/` already exists at the repo root. The command flags the collision and does not overwrite.
- The slug is not lowercase-hyphenated. The command re-asks for a conformant slug.

## Non-goals

- Does not create or approve the ADR. The ADR is authored and committed under the adopter's governance rules before this command runs.
- Does not populate the function with mandate detail beyond the one-line mandate and boundary scaffold. The owner fills these in subsequently.
- Does not activate `governance-at-scope`. It reminds the owner to do so; activation is a separate command.
- Does not create sub-specs or additional internal structure. The ADR gates the top-level folder, not its internal organisation — the owner adds those without a new ADR.

## Related

- [`./spec.md`](./spec.md) — the function capability; activation requirement, governance requirements, canonical folder structure.
- [`../governance-at-scope/spec.md`](../governance-at-scope/spec.md) — required for every function; activated separately at this scope.
- [`../governance-at-scope/adopt.md`](../governance-at-scope/adopt.md) — companion scaffolding command for the scope's governance folder.
