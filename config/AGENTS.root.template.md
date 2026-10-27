# Project - AGENTS.md

## Purpose

<!-- Replace with one-line project description -->
TODO: Project name and purpose.

## Ownership

<!-- Replace with owner/team -->
TODO: Owner or team responsible for this repo.

## Global Rules

- Load the `coding-strategy` skill before the first edit of a session, and read the file its `SKILL.md` routes you to for the task (5.9)
- Document changes in `handover.md` after every significant session, if this repo keeps one (Tier 3, 27.5); never create one to follow this line
- Record decisions in `docs/consider-features.md` - no re-litigating (copy `config/feature-tracker.template.md`; Tier 2+ projects, skip if this repo keeps no decision log)
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `clean:`
- Every behavioral change ships with its doc update - same commit, or the next one before more code lands

- **Deliberate deviations from `coding-strategy`** - one line each: the rule, why it does not
  fit here, and what would change that. Listed rules are not drift; do not "fix" them back.
  - None yet.

<!-- Add project-specific tool rules here, e.g. which MCP server to use for a given
     operation, or commands that must not be run directly. Delete this comment when filled. -->

## Work Guidance

- Read the applicable AGENTS.md chain before editing (this file + every parent/child on the path to your target)
- Update the nearest owning AGENTS.md after any meaningful change
- Use `designs/<feature-name>.md` for non-trivial features before writing code
- Run tests in isolation - no shared state, mock external deps
- Configurable paths only - no hardcoded absolute paths outside config files
- When delegating, defects you find while investigating go into the brief to be fixed, unless fixing them is risky; then say why you left them (28.5)
- When you delegate work whose code you will not read, have a second worker verify it against the task: it runs the tests, reads the diff and treats the developer's report as claims (28.6)

## Negative Constraints

<!-- Known failure modes; what agents should NOT do in this repo. Required section - see
     05-context-docs.md. -->
TODO: What NOT to do, periodic maintenance (garbage collection, dedup), output self-review rules.

- **Push only to the remote already configured here.** Do not add, rename or retarget a remote,
  and do not create a repository on a hosting service. Where this code may live is a custody
  decision the operator made once; if a push has nowhere to go, ask.

TODO: delete the line above if it does not apply, but decide deliberately - it is here because
      publishing a private codebase is one of the few mistakes no later commit undoes.

## Verification

- Lint: TODO: add linter command
- Tests: TODO: add test runner command
- Manual checks: review `handover.md` for consistency after large changes

## Child Docs Index

This project is not yet indexed. Create a child `AGENTS.md` only for a domain folder with rules of its own (5.5), list them here, and delete this message; with none yet, write "No children yet":

<!-- After indexing, populate like this:
- `api/AGENTS.md` - HTTP API handlers, routes, request/response types
- `engine/AGENTS.md` - Core pipeline stages, data flow, error handling
- `features/AGENTS.md` - Feature modules, cross-cutting rules
-->
