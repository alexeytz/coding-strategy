# Project — AGENTS.md

## Purpose

<!-- Replace with one-line project description -->
TODO: Project name and purpose.

## Ownership

<!-- Replace with owner/team -->
TODO: Owner or team responsible for this repo.

## Global Rules

- Follow the `coding-strategy` skill (Interface/Engine/Features layout, design docs first, test isolation)
- Document changes in `handover.md` after every significant session (Tier 2+ projects — skip if this repo has no `handover.md`)
- Record decisions in `docs/consider-features.md` — no re-litigating (copy `config/feature-tracker.template.md`; Tier 2+ projects, skip if this repo keeps no decision log)
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `clean:`
- Every behavioral change ships with its doc update — same commit, or the next one before more code lands

<!-- Add project-specific tool rules here, e.g. which MCP server to use for a given
     operation, or commands that must not be run directly. Delete this comment when filled. -->

## Work Guidance

- Read the applicable AGENTS.md chain before editing (this file + every parent/child on the path to your target)
- Update the nearest owning AGENTS.md after any meaningful change
- Use `designs/<feature-name>.md` for non-trivial features before writing code
- Run tests in isolation — no shared state, mock external deps
- Configurable paths only — no hardcoded absolute paths outside config files

## Negative Constraints

<!-- Known failure modes; what agents should NOT do in this repo. Required section — see
     phase-5a-context-docs.md. -->
TODO: What NOT to do, periodic maintenance (garbage collection, dedup), output self-review rules.

- **Push only to the remote already configured here.** Do not add, rename or retarget a remote,
  and do not create a repository on a hosting service. Where this code may live is a custody
  decision the operator made once; if a push has nowhere to go, ask.

TODO: delete the line above if it does not apply, but decide deliberately — it is here because
      publishing a private codebase is one of the few mistakes no later commit undoes.

## Verification

- Lint: TODO: add linter command
- Tests: TODO: add test runner command
- Manual checks: review `handover.md` for consistency after large changes

## Child DOX Index

This project is not yet indexed. Before continuing, scan the project structure, create a child `AGENTS.md` in each domain folder, and replace this message with the actual index:

<!-- After indexing, populate like this:
- `api/AGENTS.md` — HTTP API handlers, routes, request/response types
- `engine/AGENTS.md` — Core pipeline stages, data flow, error handling
- `features/AGENTS.md` — Feature modules, cross-cutting rules
-->
