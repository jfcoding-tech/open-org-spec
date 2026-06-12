# Scope Registry Query

A tool of the open-org-spec scope-registry capability. Answers routine questions about which scopes exist, who leads them, and where to route an artefact — without walking the repository.

**Status:** Draft (0.1.0)
**Type:** Command
**Reference implementation:** an adopter executes the base spec via a relay at their command directory (e.g. `.claude/commands/scope-registry.md` for Claude Code adopters), optionally extended at `.open-org-spec/extensions/tooling/scope-registry/spec.md`.

---

## Purpose

Every artefact-routing and governance-conformance operation in a conformant repository eventually needs to answer one of a small set of questions: what scopes exist? who leads each one? where does a given `type/slug` reference resolve to? which scopes are under-provisioned?

Without a catalogue, each operation answers these by walking the repository — slow, fragile, and redundant. The scope registry query command provides a fast, readable interface to `governance/catalogue/scopes.yaml`, the machine-generated catalogue produced by the scope registry agent. Routine queries become single-file reads; the repo walk becomes a fallback, not the default.

The command is the human-facing complement to the agent's machine-facing contract. Where the agent writes and maintains the catalogue, this command reads and presents it.

---

## Pattern

### Catalogue source

Before running any query form, the command:

1. Reads the adopter-declared catalogue path (default: `governance/catalogue/scopes.yaml`).
2. Checks the `generated` timestamp. If the catalogue is absent or older than 25 hours, falls back to a repo walk using the scope discovery rules in `spec.md`. Outputs a `[catalogue-stale]` notice on the first line of the response so the contributor knows the result came from a live walk, not the cached catalogue.
3. Proceeds with the query against whichever source was used.

The `[catalogue-stale]` notice is informational, not an error. The command continues and returns results.

---

### Query forms

#### `list` — all active scopes

**Syntax:** `/scope-registry list`

**What it does:** reads the catalogue and returns all entries with `status: active` in a table. Closed scopes are excluded unless the `--all` flag is passed.

**Output shape:**

```
| Type      | Slug                          | Path                              | Lead                  | Feedback inbox                                 |
|-----------|-------------------------------|-----------------------------------|-----------------------|------------------------------------------------|
| cluster   | product-development           | clusters/product-development      | Yaiza Temprado        | clusters/product-development/feedback.md       |
| function  | revenue                       | functions/revenue                 | Howard Tunnicliffe    | functions/revenue/feedback.md                  |
| project   | agentic-coach-phase-3         | projects/agentic-coach-phase-3    | TBD                   | projects/agentic-coach-phase-3/feedback.md     |
| module    | ai-factory                    | ai-factory                        | Javier Fernandez      | ai-factory/feedback.md                         |
| programme | programme                     | .                                 | <manifest owner>      | governance/feedback.md                         |
```

Rows are sorted: `programme` first, then `module`, then `cluster`, then `function`, then `project`. Within each type, rows are sorted alphabetically by slug. This ordering surfaces the structural backbone before the transient initiatives.

When `--all` is passed, closed scopes appear at the end of their type group, with `[closed]` appended to the slug cell.

---

#### `find <person>` — scopes where a person holds a function

**Syntax:** `/scope-registry find <name>`

**What it does:** looks up every scope in the catalogue, reads the `people.md` at each scope's `path`, and returns all scopes where `<name>` appears — with the function they hold at each scope. The catalogue provides the scope list; the `people.md` files provide the function detail. Only active scopes are searched by default.

**Output shape:**

```
Scopes where Howard Tunnicliffe holds a function:

| Type     | Slug     | Function | Feedback inbox                      |
|----------|----------|----------|-------------------------------------|
| function | revenue  | Lead     | functions/revenue/feedback.md       |
| cluster  | customer-lifecycle | Liaison | clusters/customer-lifecycle/feedback.md |
```

If `<name>` matches no entry in any `people.md`: outputs `No scopes found for "<name>". Check spelling or use /scope-registry list to see all scope leads.`

Name matching is case-insensitive and tolerates partial matches (first name alone, last name alone). When a partial match is ambiguous, the command lists the candidates and asks the contributor to disambiguate before returning results.

---

#### `routing <type>/<slug>` — resolve a scope reference to a feedback inbox

**Syntax:** `/scope-registry routing <type>/<slug>`

**What it does:** looks up the given `type/slug` pair in the catalogue and returns the resolved feedback inbox path. This is the same resolution a routing agent performs — exposed here for human inspection and debugging.

**Output shape (resolved):**

```
scope: function/revenue
feedback_inbox: functions/revenue/feedback.md
lead: Howard Tunnicliffe
status: active
```

**Output shape (not found):**

```
[scope-not-found] "function/nonexistent" does not match any entry in the scope registry.

Active scopes of type "function":
  - function/revenue  →  functions/revenue/feedback.md

Use /scope-registry list to see all scopes.
```

**Output shape (closed scope):**

```
[scope-closed] "project/claire-busuu-live-v0" is in the registry with status: closed.
Closed scopes are not routing targets. Route to the nearest active parent scope,
or use "programme" if no parent scope applies.

Nearest active parent: programme  →  governance/feedback.md
```

The `routing` form is the primary debugging tool for contributors who receive a `[scope-not-found]` warning from an agent. It tells them exactly what the agent saw and what alternatives are available.

---

#### `leads` — all scopes with their leads; flag TBD

**Syntax:** `/scope-registry leads`

**What it does:** returns a two-section output — scopes with a named lead, then scopes where the lead is `TBD`. The `TBD` section is a governance gap: ungoverned scopes cannot be routed to.

**Output shape:**

```
Scopes with named leads:

| Type     | Slug                  | Lead               | Feedback inbox                                    |
|----------|-----------------------|--------------------|---------------------------------------------------|
| cluster  | product-development   | Yaiza Temprado     | clusters/product-development/feedback.md          |
| function | revenue               | Howard Tunnicliffe | functions/revenue/feedback.md                     |
| module   | ai-factory            | Javier Fernandez   | ai-factory/feedback.md                            |
| programme| programme             | Javier Fernandez   | governance/feedback.md                            |

Scopes with no named lead (TBD):

| Type    | Slug                      | Feedback inbox                                  |
|---------|---------------------------|-------------------------------------------------|
| project | agentic-coach-phase-3     | projects/agentic-coach-phase-3/feedback.md      |

1 scope(s) are ungoverned. Artefacts routed to these scopes will fall back to governance/feedback.md until a lead is assigned.
```

If all leads are named: the `TBD` section is omitted and the output ends with `All active scopes have named leads.`

---

#### `stale` — scopes with missing, closed, or null-inbox catalogue entries

**Syntax:** `/scope-registry stale`

**What it does:** returns scopes that are in one of three problematic states:

1. **Missing from catalogue** — a `people.md` or scope README exists in the repo but the scope has no catalogue entry. This means the scope registry agent has not been run since the scope was created, or the scope's folder does not match the discovery heuristics.
2. **Closed** — scopes with `status: closed` in the catalogue. Included here as a maintenance surface: closed scopes should either be archived (removed from active paths) or reopened. They are not routing targets.
3. **Null feedback inbox** — scopes where `feedback_inbox: null` in the catalogue. Artefacts routed to these scopes fall back to the parent scope's inbox silently — a gap that should be resolved by creating the `feedback.md`.

**Output shape:**

```
Stale catalogue entries:

Missing from catalogue (found in repo, not in scopes.yaml):
  - clusters/emerging-markets  [no catalogue entry — run /scope-registry generate to update]

Closed scopes (not routing targets):
  - project/claire-busuu-live-v0  [status: closed, path: projects/closed/claire-busuu-live-v0]

Scopes with no feedback inbox (null routing target):
  - project/agentic-coach-phase-3  [feedback_inbox: null — create projects/agentic-coach-phase-3/feedback.md]

3 issue(s) found. Run /scope-registry generate to refresh the catalogue, or resolve each gap manually.
```

If no stale entries: outputs `Catalogue is clean. All active scopes have entries and feedback inboxes.`

The `stale` form is intended as a routine maintenance check — run after any structural reorganisation, after a new scope is created, or as part of a periodic governance review.

---

### Fallback: repo walk

When the catalogue is absent or stale, the command performs a minimal repo walk using the scope discovery rules from `spec.md`:

- Clusters — immediate subdirectories of `clusters/` (excluding `governance/`, `context/`, `_template/`, `closed/`)
- Functions — immediate subdirectories of `functions/` (excluding `_template/`, `closed/`)
- Projects — immediate subdirectories of `projects/` (excluding `_template/`, `closed/`)
- Modules — folders declared in the manifest or matching known module patterns
- Programme — always present; one entry at the repo root

For each discovered scope, the command infers `feedback_inbox` by checking whether `<path>/feedback.md` exists, and infers `lead` by reading the lead table in `<path>/people.md` if present.

The `[catalogue-stale]` notice appears at the top of any output produced via repo walk, regardless of which query form is in use. It includes the age of the stale catalogue (if one exists) or `[catalogue-absent]` if no file was found at the declared path.

---

## What is not prescribed

- **The exact CLI invocation style.** The query forms and their output shapes are specified; whether they are invoked as `/scope-registry list` or `/scopes list` or another alias is an adopter decision declared in the relay.
- **Whether results are streamed or batched.** The command may return results line by line as it reads each scope's `people.md`, or it may read everything first and return a single table. Both are conformant.
- **Pagination.** Adoptions with large scope counts may need paginated output; this is an extension point. The base spec does not prescribe pagination behaviour.
- **The `--all` flag implementation.** The flag is described as a convention for including closed scopes in `list`. The adopter's relay or extension may implement it differently, or not at all, provided the default behaviour (active scopes only) is preserved.

---

## Rationale

A scope registry without a query interface is a file. The query command is what makes the registry a service: it absorbs the mechanical steps (read YAML, check timestamps, fall back to walk, format a table) so contributors and agents do not repeat them. The five query forms cover the four recurring operational questions — what exists, who leads it, where does this reference go, and what is broken — plus one maintenance form for keeping the catalogue current.

The `routing` form is specifically designed for debugging: when an agent surfaces a `[scope-not-found]` warning on a risk or artefact, the first thing a contributor needs is exactly what `/scope-registry routing` returns — the catalogue's view of that reference, and what alternatives are available. Making this inspection a first-class query form collapses a multi-step debug sequence into a single command invocation.

---

## Related

- [`spec.md`](./spec.md) — scope-registry capability; scope reference format, catalogue schema, and scope discovery rules
- [`agent.md`](./agent.md) — scope registry agent; generates and maintains `scopes.yaml`
- [`../../feedback-inbox/spec.md`](../feedback-inbox/spec.md) — defines the `feedback.md` convention that this command surfaces as routing targets
- [`../../people/spec.md`](../people/spec.md) — defines the `people.md` shape that the `find` query reads for function data
- [`../../adoption-manifest/spec.md`](../adoption-manifest/spec.md) — the manifest's scope tree declaration informs the repo walk fallback
