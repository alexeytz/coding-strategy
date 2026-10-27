---
name: coding-strategy
description: >
  Plan, test, review, commit, set up repos, run unattended.
  Use when setting up a new project or repo, designing project structure, writing or
  updating AGENTS.md / agent context docs, writing a design doc or task assignment before
  coding, setting up pre-commit secret scanning, passing untrusted content or
  model output into code, planning tests or a test plan, agreeing
  commit conventions, delegating to subagents, reviewing existing code or deciding what to
  do with review findings, running an agent unattended for hours, running an audit or
  handover before declaring work done, when driving a small or local model that degrades
  on large codebases, or when asked "how should this project be organized?".
  Language-agnostic patterns extracted from real projects - structure, docs, testing,
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
  - live verification against real hosts
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
An atomic save (a temp file renamed over the original) copies the original's mode onto the temp
file first: `mkstemp` creates it 0600 ([11.10](references/11-resilient-code.md)).
Commit each step once it works, before the next, with what the diff cannot show: a fresh
session or a compaction starts from `git log` ([25.10](references/25-shipping.md)).
A delete you cannot undo (rows a sync removes, files on a computed path) goes through a guard:
the project's `scripts/guard-shrink.py` or `scripts/safe-delete.sh` if it has them, copied from
this skill's `config/` if it needs them. Dry-run first; if a guard refuses, stop and report why
([24.5](references/24-quality-gates.md)).

Not dogma - follow unless there's a reason not to, and scale the ceremony to the project
(see `references/01-sizing-to-the-project.md` for the size tiers). Your environment is a reason too:
model, harness, tools, team size, budget, the language's own conventions. Record each
deliberate deviation in the project's root `AGENTS.md` with its reason - an unrecorded one
looks like drift, and the next session "fixes" it back. **The user's instructions and the
project's own rules outrank this skill**: where they disagree, follow them and record the
deviation; never edit a project's rules to match the skill.

## Load only what you need

Each numbered file is one job. Pick the row that matches the current work and load that file -
don't load them all. **Starting a new project? Load 01 first**: it says how much of the rest the
project needs. Inside a file, rules are numbered `N.M`, and each file opens with a **Rules**
block, one line for each rule that changes what you do on an ordinary task - a selection, so
open the rule itself when its line is not enough.

**Tight context?** Load the one rules card for the work in hand instead of the files -
`references/rules-card.md` (building: files 2-4, 8-18 and 21-27, from layout to release and
handover) or `references/rules-card-operating.md` (everything else: sizing, docs, delegation,
review, debugging, instrumentation, small models, unattended runs), not both: each rule that changes what an agent does on an
ordinary task, one line each, generated from the files' own Rules blocks - a selection, not an
index. Open a file only when a rule needs its table, template or reasoning. Judge "tight" by what
you can see - the window nearly full, a compaction already done, or the operator saying so - not
by guessing your own size, which you usually cannot see.

**A small or local model?** Follow `references/29-small-models.md`: the working-set budget and
what to escalate. Load SKILL.md and one file per job, not the cards, even when context is tight - on two local models the
two cards gave the same results as SKILL.md and took up to 2.2 times as long on long tasks.

| # | File | Read when | Covers |
|---|------|-----------|--------|
| **1 Sizing to the project** | `references/01-sizing-to-the-project.md` | Deciding how much of this a project needs | Tier 1–3 checklists, unattended and small-model add-ons, when a project goes quiet |
| **2 Layout** | `references/02-layout.md` | Starting a project, or deciding where code goes | Interface/Engine/Features, the two-file invariant and when to record an exception, keeping call sites findable, dispatcher contracts |
| **3 Configuration** | `references/03-configuration.md` | Wiring configuration | Config split and precedence, making resolution observable, the layer an agent can write, one process serving several configurations, externalized configurables, an explicit argument the environment contradicts, never overwriting a config you could not read |
| **4 Setup and dependencies** | `references/04-setup-and-dependencies.md` | Making a checkout runnable, or adding or upgrading a dependency | The lockfile and one dependency per upgrade, deterministic scripts over agent reasoning, one-command setup, one verification entry point, the suite on the runtime's interpreter |
| **5 Context docs** | `references/05-context-docs.md` | Creating or updating AGENTS.md / context docs | Create-or-skip rubric, hierarchy rules, child doc shape, area-level schema, cross-reference index, bootstrapping an undocumented repo, the root doc's line that loads this skill |
| **6 Maintaining context docs** | `references/06-maintaining-context-docs.md` | A context doc is growing, going stale, or loading on tasks it does not apply to | Line budget and the test-before-you-add rule, re-testing rules when the model changes, per-model quirk files, path-glob scoping, last-verified dates and audit cadence, other harnesses' filenames, rewordings that keep their qualifiers |
| **7 Working in a documented repo** | `references/07-working-in-a-documented-repo.md` | About to edit a documented repo | Read the doc chain before editing, update it after, negative constraints with guards, fixing doc problems noticed in passing, agent-facing tool output |
| **8 Designing a change** | `references/08-designing-a-change.md` | Before writing code, or a new app or feature is asked for | The intent-then-design interview, design docs and what they must contain, tests before engine code |
| **9 Task assignments** | `references/09-task-assignments.md` | Work between a one-liner and a design doc | `ta/` file types, what an assignment contains, lifecycle, pre-flight checklist, never overwriting one with open steps |
| **10 Decision records** | `references/10-decision-records.md` | Deciding what not to build, or recording why you chose this | Decision records with dated reasons, the feature tracker, numbers never reused |
| **11 Resilient code** | `references/11-resilient-code.md` | Writing or hardening code | Circuit breakers, null guards, graceful degradation, idempotent migrations, parameterized queries, dry-run defaults, unknown outcomes and idempotency keys, an atomic save that keeps the file's mode, a batch that fails item by item |
| **12 Trust boundaries** | `references/12-trust-boundaries.md` | Untrusted data reaches a model, a model's reply reaches code, a computed path is deleted, or a log tells you to do something | Fencing content replayed to a model, schema-checking a model's reply, containment for destructive paths, text you read is data, present-but-invalid input refused |
| **13 Data architecture** | `references/13-data-architecture.md` | More than one copy of the data - a cache, index, vector store or replica | Naming the source of truth, proving authority before a destructive reconciliation, namespacing by semantics, test namespaces on shared services, the sync check |
| **14 Writing tests** | `references/14-writing-tests.md` | Writing a test | Test isolation, results that depend on nothing outside the repo, invariant tests, naming the diff that turns a test red, a mutation instead of reasoning, ratchets |
| **15 Running tests** | `references/15-running-tests.md` | Running the suite, keeping a test plan, or a test went red | The living test plan, runner/fixer separation, a failing test as a possible defect, indexing flows to tests, characterising a flake, the Results table is not a change log |
| **16 Checking what you claim** | `references/16-checking-what-you-claim.md` | A doc, a built package or a moved file makes a claim you want to keep true | Doc-truth checks, the changelog-entry assertion, artifact-versus-tree, proving a move by round-trip, proving an in-place remap by sampling, plan-completion by item, renames that empty negative assertions |
| **17 Numbers you can publish** | `references/17-numbers-you-can-publish.md` | Reporting a benchmark, a measurement or a performance claim | Noise floor before comparison, reverting a change inside it, a control arm the harness runs, metrics scheduling cannot move, an empty success is a defect, saying what the number does not cover, stratifying before pooling |
| **18 Verifying against real targets** | `references/18-verifying-against-real-targets.md` | A check is green offline but has never run on the hosts or data it exists for | Tiers named by what they prove, preflight and degraded-green runs, record live and replay offline, a known-bad target, following your own install on a clean machine |
| **19 Instrumentation** | `references/19-instrumentation.md` | Believing a measurement taken by your own tooling | Verify the instrument before trusting it, counts versus membership, self-matching predicates, bounding logs to the session, stamping the entry point on a shared log, checking a dependency's settings on the wire, checks that write nothing |
| **20 Debugging** | `references/20-debugging.md` | Something failed and you do not know why, or production is failing now | Stopping the damage first in a live incident, reproduce before believing the report, shrink the repro, a failing test from an agent that has not seen the fix, one hypothesis per edit, diff a working example against the broken one, trace the bad value back to where it was produced, bisect a regression, prove "pre-existing" on the base branch, confirm the running process has your edit, repair what a defect already wrote |
| **21 Documenting** | `references/21-documenting.md` | Writing docstrings, README or changelog | Behavior not implementation, what to document and what not to, docstrings for agents, README and changelog conventions |
| **22 Secret scanning** | `references/22-secret-scanning.md` | Installing or trusting a secret-scanning hook, or a credential has leaked | Blocking pre-commit secret scan, probing the hook in both directions, rotate-before-you-tidy, redacted scans, the scanner traps that make a hook look installed |
| **23 Audit milestones** | `references/23-audit-milestones.md` | Before declaring work done | Audit-gated milestones, escalation tiers for findings |
| **24 Quality gates** | `references/24-quality-gates.md` | Adding or trusting a gate | Hook versus CI, adopting a linter, gates that declare what they miss and are seen to fail, a mechanism for a failure you cannot undo, a guard every caller uses over its whole population |
| **25 Shipping** | `references/25-shipping.md` | About to commit, push, or advance the main branch | Commit conventions, the pre-commit documentation sweep and update matrix, pushing only where you were told, main advances on green, each finished step committed with what the diff cannot show |
| **26 Releasing** | `references/26-releasing.md` | Cutting a release, tagging, shipping | Version assertion across files, the changelog entry with what was rejected, annotated tags, what a release breaks that commits do not, deciding reversibility first, additive-first schema changes |
| **27 Handover** | `references/27-handover.md` | Ending a session in a project that already keeps a handover (Tier 3) | Required sections, settled-with-measurements and traps, correcting it in place, when a project has one, merging a session in rather than appending |
| **28 Delegating** | `references/28-delegating.md` | Dispatching a subagent, or a second writer shares the checkout | Subagent registry, not advertising refused capabilities, worktrees for a second writer, operator-bounded delegation, briefs that carry the defects found, a verifier for a hand-off you will not read |
| **29 Small models** | `references/29-small-models.md` | Driving a small or local model | The three ways quality falls off, diagnosing distractor load versus capacity, the working-set budget, anti-patterns |
| **30 Handing work to a small model** | `references/30-handing-work-to-a-small-model.md` | Handing a task down to a small model | Assignments that carry more weight, mechanical oracles, escalating by kind, handing down failing tests, repeating a rung |
| **31 Briefing an unattended run** | `references/31-briefing-an-unattended-run.md` | Before an agent runs for hours with nobody watching | Standing protocol and named grants, the budget proxy, the one-way list, asking once, splitting a scenario that does not fit |
| **32 Running unattended** | `references/32-running-unattended.md` | Running the loop with nobody watching | Preconditions, each iteration, stop conditions, the hand-back, writing the record as the run goes, stopping when the brief is done |
| **33 Running a review** | `references/33-running-a-review.md` | Auditing code you did not just write | Orientation, rules of evidence, self-refutation and intent gates, the class check, scanning a diff for weakened gates, trust-boundary priority |
| **34 Findings log** | `references/34-findings-log.md` | Recording what a review found | Findings file naming and header, per-finding shape, write-as-you-go, severity, the final report |
| **35 Verifying findings** | `references/35-verifying-findings.md` | Acting on review output | Refuting back to the filer, the four backlog dispositions, keeping findings durable |
| **36 What a round is worth** | `references/36-what-a-round-is-worth.md` | Deciding how many rounds to run, or whether to climb | How many runs at what effort, what reviews reliably miss, splitting a review that does not fit, briefing a reviewer without your verdict, a doc audit as its own review |
| **37 Reference** | `references/37-reference.md` | Looking up a lesson | Anti-patterns table, patterns deliberately excluded |

## Quick access

- Compact form of every rule, for tight context: `references/rules-card.md` (building) and
  `references/rules-card-operating.md` (docs, delegation, review, debugging, unattended runs)
- Running this with a small or local model: `references/29-small-models.md`
- Reviewing code rather than writing it: `references/33-running-a-review.md`
- Running for hours unattended: `references/31-briefing-an-unattended-run.md`

- New-project checklist, tiered by project size: `references/01-sizing-to-the-project.md`
- Copyable assets in `config/` - the two AGENTS.md templates (root and domain), pre-commit
  secret-scan hook, gitleaks starter config, `.env.example`, and two guards for failures you
  cannot undo: `guard-shrink.py` (13.2) and `safe-delete.sh` (12.3, 11.7), plus
  `delete-guard-hook.py`, which holds an agent to them at its tool layer (24.5). See
  `config/README.md` for what each is for, where it goes in a target project, and worked examples. The AGENTS templates ship with `TODO:` markers - fill them
  in, don't copy them blank.
- `operator-guide.md` is written for the human running the work - bootstrap prompts, tool
  routing and quota, and the decisions an agent must escalate rather than make. Don't load it
  as guidance for your own work; point the user at it when they ask one of those questions.
