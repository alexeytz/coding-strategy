---
name: coding-strategy
description: >
  Use when setting up a new project or repo, designing project structure, writing or
  updating AGENTS.md / agent context docs, writing a design doc or task assignment before
  coding, setting up pre-commit secret scanning, planning tests or a test plan, agreeing
  commit conventions, delegating to subagents, reviewing existing code or deciding what to
  do with review findings, running an agent unattended for hours, running an audit or
  handover before declaring work done, when driving a small or local model that degrades
  on large codebases, or when asked "how should this project be organized?".
  Language-agnostic patterns extracted from real projects — structure, docs, testing,
  quality gates, agent operations.
triggers:
  - new project setup
  - project structure design
  - one-command setup
  - writing AGENTS.md
  - agent context navigation
  - design doc creation
  - pre-commit security
  - secret scanning
  - test plan creation
  - test timing
  - commit conventions
  - subagent delegation
  - handover protocol
  - audit milestones
  - coding standards
  - error resilience
  - task assignment
  - code review protocol
  - verifying review findings
  - refuting a finding
  - unattended or overnight agent runs
  - documentation-truth tests
---

# Coding Strategy

Thin interface, fat engine, pluggable features. One feature touches at most 2 source files.
Design doc before code. Docs ship with the change. Tests in isolation.

Not dogma — follow unless there's a reason not to, and scale the ceremony to the project
(see `references/project-checklist.md` for the size tiers).

## Load only what you need

Each phase is a separate file. Read the one that matches the current work — don't load them all.

**Tight context, or a small/local model?** Load `references/rules-card.md` (building) and `references/rules-card-operating.md` instead — every rule
in this skill, one line each, at roughly a fifth of the cost of a phase file. Open a phase file
only when a rule needs its table or template. See `references/small-model-operation.md` for the
working-set budget and what to escalate.

| Phase | File | Read when | Covers |
|-------|------|-----------|--------|
| **1a: Layout** | `references/phase-1a-layout.md` | Starting a project, or deciding where code goes | Interface/Engine/Features, the two-file invariant and when to record an exception, keeping call sites findable, dispatcher contracts |
| **1b: Config and setup** | `references/phase-1b-config-and-setup.md` | Wiring configuration, or making a checkout runnable | Config split and precedence, making resolution observable, externalized configurables, one-command setup, one verification entry point |
| **2a: Designing a change** | `references/phase-2a-designing-a-change.md` | Before writing code, planning a feature | Design docs (incl. test timing), interview loop, task assignments (`ta/`) |
| **2b: Recording & shipping** | `references/phase-2b-recording-and-shipping.md` | Deciding what not to build, or about to commit | Decision records and the feature tracker, commit conventions, the pre-commit documentation sweep |
| **3a: Writing resilient code** | `references/phase-3a-writing-resilient-code.md` | Writing or hardening code | Pre-commit secret scanning, circuit breakers, null guards, graceful degradation, idempotent migrations, parameterized queries |
| **3b: Verifying** | `references/phase-3b-verifying.md` | Writing tests or a test plan | Test isolation, living test plan, runner/fixer separation, naming a tier by what it proves, doc-truth checks |
| **3c: Documenting** | `references/phase-3c-documenting.md` | Writing docstrings, README or changelog | Behavior not implementation, what to document and what not to, docstrings for agents, README and changelog conventions |
| **3d: Checking what you claim** | `references/phase-3d-checking-what-you-claim.md` | A doc, a built package or a moved file makes a claim you want to keep true | Doc-truth checks, the changelog-entry assertion, artifact-versus-tree, proving a move by round-trip |
| **4: Quality gates** | `references/phase-4-quality-gates.md` | Before declaring work done | Audit-gated milestones, escalation tiers, handover protocol |
| **5a: Context docs** | `references/phase-5a-context-docs.md` | Creating or updating AGENTS.md / context docs | Create-or-skip rubric, hierarchy rules, child doc shape, area-level schema, cross-reference index, bootstrapping an undocumented repo |
| **5b: Working & delegating** | `references/phase-5b-working-and-delegating.md` | About to edit a documented repo, or dispatching a subagent | Read the doc chain before editing, update it after, agent-facing tool output, subagent registry |
| **5c: Maintaining context docs** | `references/phase-5c-maintaining-context-docs.md` | A context doc is growing, going stale, or loading on tasks it does not apply to | Line budget and the test-before-you-add rule, path-glob scoping, last-verified dates and audit cadence, other harnesses' filenames |
| **6: Reference** | `references/phase-6-reference.md` | Looking up a lesson | Anti-patterns table, patterns deliberately excluded |
| **7a: Running a review** | `references/phase-7a-running-a-review.md` | Auditing code you did not just write | Orientation, rules of evidence, self-refutation and intent gates, the class check, trust-boundary priority |
| **7b: Findings log** | `references/phase-7b-findings-log.md` | Recording what a review found | Findings file naming and header, per-finding shape, write-as-you-go, severity, the final report |
| **7c: Verifying findings** | `references/phase-7c-verifying-findings.md` | Acting on review output | Refuting back to the filer, the four backlog dispositions, keeping findings durable |
| **7d: What a round is worth** | `references/phase-7d-what-a-round-is-worth.md` | Deciding how many rounds to run, or whether to climb | How many runs at what effort, what reviews reliably miss, splitting a review that does not fit |
| **8a: Unattended runs** | `references/phase-8a-unattended-runs.md` | Running for hours with nobody watching | Standing protocol and named grants, the loop, stop conditions, the budget proxy, the one-way list, the hand-back |
| **8b: Instrumentation** | `references/phase-8b-instrumentation.md` | Believing a measurement taken by your own tooling | Verify the instrument before trusting it, counts versus membership, self-matching predicates, bounding logs to the session |
| **9: Releasing** | `references/phase-9-releasing.md` | Cutting a release, tagging, shipping | Version assertion across files, the changelog entry with what was rejected, annotated tags, what a release breaks that commits do not, deciding reversibility first |
| **10: Data architecture** | `references/phase-10-data-architecture.md` | More than one copy of the data — a cache, index, vector store or replica | Naming the source of truth, proving authority before a destructive reconciliation, namespacing by semantics, test namespaces on shared services, the sync check |

## Quick access

- Compact form of every rule, for tight context: `references/rules-card.md`
- Running this with a small or local model: `references/small-model-operation.md`
- Reviewing code rather than writing it: `references/phase-7a-running-a-review.md`
- Running for hours unattended: `references/phase-8a-unattended-runs.md`

- New-project checklist, tiered by project size: `references/project-checklist.md`
- Copyable assets in `config/` — the two AGENTS.md templates (root and domain), pre-commit
  secret-scan hook, gitleaks starter config, `.env.example`. See `config/README.md` for where
  each one goes in a target project. The AGENTS templates ship with `TODO:` markers — fill them
  in, don't copy them blank.
- `operator-guide.md` is written for the human running the work — bootstrap prompts, tool
  routing and quota, and the decisions an agent must escalate rather than make. Don't load it
  as guidance for your own work; point the user at it when they ask one of those questions.

## Keeping this skill honest

`tests/check-docs.sh` enforces the structural invariants — links resolve, the routing table
matches what is on disk, each numbered section appears in exactly one file, no reference file
exceeds its per-load budget, and prose cross-references point at the file that actually holds
the section. Run it after editing any doc here. `--self-test` seeds a break for each guard and
requires it to fail, because a check nobody has watched go red is not evidence.

Development of this skill — its design docs, the backlog of lessons not yet absorbed, the bug
log, and the session handover — lives in a separate repository. This one carries the skill.
