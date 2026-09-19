# Rules card

The rules an executing agent needs on an ordinary task, one line each, no rationale. **Load this
instead of a phase file when context is tight** — about a fifth of the cost. Open the named phase
file for detail, for a table or template, and for any job whose rules are situational.

Rationale persuades a reader who might disagree. If you are executing, you need the rule.

**A selection, not an index** — a card that grows with the strategy is a second copy of it. Rules
that fire only in a named situation stay in their phase file, where you are already going to be.
Dropping a line here deletes nothing.

## Layout — detail in [phase-1a-layout.md](phase-1a-layout.md)

- `interface/` holds types, schemas, dispatch, routing. Nothing else.
- `engine/` holds logic, pipelines, CRUD, external integrations.
- `features/` holds one module per capability.
- A feature touches at most 2 source files. Needing 5 means the interface is wrong — fix that, don't spread the feature.
- Record an honest over-count in the design doc; never hide call sites behind indirection to satisfy it.
- Keep call sites greppable — no names built at runtime; one literal table when you need indirection.
- Once several modules compete for one input, the dispatcher asserts the contract and names every candidate it tried.

## Config and setup — detail in [phase-1b-config-and-setup.md](phase-1b-config-and-setup.md)

- Structural config (collections, weights, flags) goes in JSON/YAML; host config (URLs, paths, keys) goes in `.env`.
- Precedence is env var > config file > hardcoded default.
- Document every variable in `.env.example` with REQUIRED/OPTIONAL and its default.
- Never commit secrets. `.env.example` carries placeholders only.
- Regexes, prompts, thresholds and entity lists live in `config/` data files, never as literals in code.
- Print which layer won for every layered value; keep authored and effective config as two objects.
- A value an agent writes to a shadowed layer is persisted and inert — write to the winning layer or refuse.
- Multi-tenant in one process: the tenant goes in the cache key and in anything constructed once.
- Verification lives in `scripts/verify.sh`; hooks and CI call it and hold no logic. Gate stages on a capability, not a machine.
- Any deterministic sequence of 3+ steps becomes a script in `scripts/`, not agent reasoning.

## Designing a change — detail in [phase-2a-designing-a-change.md](phase-2a-designing-a-change.md)

- A change spanning 3+ methods or touching the schema gets `designs/<feature>.md` before code.
- A design doc contains: problem, numbered approach, schema changes, edge-case table, performance estimate, rollback plan.
- Order of work: design doc → test skeleton → engine code → tests pass.
- A contradictory assignment is a question for the user, not a choice for you.

## Recording & shipping — detail in [phase-2b-recording-and-shipping.md](phase-2b-recording-and-shipping.md)

- Every feature idea gets a numbered decision-log entry with a dated reason, open ones included. Numbers are never reused.
- Commit types: `feat` `fix` `docs` `test` `clean`.
- Push only to the remote you were given. Never add, retarget or create one — hosting is the operator's call.
- Every behavioral change ships its doc update in the same commit: walk the doc-update matrix against the staged diff, and write the changelog entry then. When a row's drift recurs, replace it with a check.

## Writing resilient code — detail in [phase-3a-writing-resilient-code.md](phase-3a-writing-resilient-code.md)

- Circuit-break external dependencies after N consecutive failures; fall back; reset on success.
- An inner `try` that swallows a failure makes the breaker around it permanently inert.
- One `try` over two subsystems misnames every failure of the second. Split it.
- A degraded-feature message names the command that fixes it, and a check keeps that command resolving.
- Guard every external return value for null before using it.
- An optional dependency that fails is logged and skipped, never fatal.
- Migrations are idempotent and safe to re-run.
- One logger, one configuration, level from an env var.
- Queries are parameterized always; column names come from a hardcoded allowlist.
- Destructive actions default to dry-run on every surface.
- A surface that deliberately diverges from a rule documents the divergence at the divergence.
- Content your system did not author is fenced before it reaches a model; absent provenance means untrusted.
- A caller can never set a trust label to a self-authored value.

## Verifying — detail in [phase-3b-verifying.md](phase-3b-verifying.md)

- Tests run isolated: temp dirs and DBs, mocked externals, no shared state, one file per feature area.
- A test runner reports; a test fixer fixes the code. Never rewrite a test to make it pass.
- A preflight test validates deps and config and fails fast.
- Assert questions about the repo; print questions about this machine.
- Prefer invariants that would have failed before the fix landed over shape assertions.
- Every test names the future diff that would turn it red; if the answer is "editing the test", delete it.
- A ban the tree violates gets a ratchet: pin the count, fail on any rise and any unbanked fall.
- Index flows to tests, not only tests to assertions — an uncovered flow is a row, not a silence.
- Characterise a flake by looping it and recording the rate; rerun-and-green is not a fix.

## Documenting — detail in [phase-3c-documenting.md](phase-3c-documenting.md)

- Don't document obvious code, implementation detail, change history, or TODOs.
- README answers: what, why, how to run, how to extend, known limits.

## Checking what you claim — detail in [phase-3d-checking-what-you-claim.md](phase-3d-checking-what-you-claim.md)

- Make doc drift fail mechanically: documented counts, `file:NNN` references, generated files, cited paths.
- The version being tagged has a changelog entry; assert it.
- Don't write an exact count or byte figure into prose. Cite the band.
- If you ship an artifact, one test builds it and asserts the invariant there, and fails rather than skips when the build tool is missing.
- A move that preserves content is proved by round-trip against the pinned pre-move commit, not by review.
- An in-place remap of numbers or IDs is proved by sampling pointers against content; the pointer checks go vacuous.
- A generated file carries a generator-written header, and a check asserts the header is there.

## Pre-commit security — detail in [phase-3e-pre-commit-security.md](phase-3e-pre-commit-security.md)

- Secret scanning runs as a blocking pre-commit hook, and fails closed when no scanner is installed.
- A secret that reached a remote is burned: rotate first, clean history second, fix the hook third.
- Probe the hook in both directions: a live-looking token must block, a clean commit must pass.

## Numbers you can publish — detail in [phase-3f-numbers-you-can-publish.md](phase-3f-numbers-you-can-publish.md)

- Publish the noise floor before any A/B — one arm against itself, three runs. Under the floor is not a result.
- Prefer a counter to a timing; compare against a control arm the harness runs, not against nothing.
- Derive the exit code from the predicate the report prints; an empty success is a defect.
- Every gate, spec and results table names what it does not cover, and what defeats it if protective.

## Quality gates — detail in [phase-4-quality-gates.md](phase-4-quality-gates.md)

- A milestone is done only after a dated audit: tests, security scan, dangerous patterns, performance, lint, bug count, GO/NO-GO.
- Break the thing a gate watches and see it go red before trusting it green; never pipe the checked command into anything.
- Every grader carries a known-good and a plausible-wrong reference and refuses to run when it cannot rank them.
- Classify every finding as auto-fix, queue-for-review, escalate, or block. Default to auto-fix.
- Escalate anything touching public API shape, auth, security boundaries, or a migration that can lose data.
- `handover.md` carries load order, current state, recent commits, test status, remaining work, known limitations.
## Releasing — detail in [phase-9-releasing.md](phase-9-releasing.md)

- Suites green before the tag, never after.
- A script asserts every file carrying the version agrees; two files disagreeing is an unreasonable release.
- The tagged version has a changelog entry, and the entry says what was tried and rejected.
- Annotated tags, pushed together with the commits they name.
- Decide what undoes the release before pushing it; "nothing" means stage it or flag it.

## Data architecture — detail in [phase-10-data-architecture.md](phase-10-data-architecture.md)

- Name the source of truth in one sentence. A derived store that cannot be rebuilt from it is an undeclared second source.
- Before deleting from one store on the strength of another, refuse if the authority is empty, smaller, disjoint, or uncountable.
- Namespace a derived store by what determines its semantics, never by a property that merely correlates.
- On a shared real service, tests get their own prefix and refuse to run without one.
- Ship a sync check with an exit code derived from the predicate it prints.

---

Operating rules — context docs, delegation, review, unattended runs — are in
[rules-card-operating.md](rules-card-operating.md).
