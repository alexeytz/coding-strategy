# 1 Sizing to the project

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Scale the ceremony to the project. Every artifact below costs time to create and, worse, time
to keep true - a stale `handover.md` is more harmful than no `handover.md`. Pick the tier that
matches what you're building. Its list is a ceiling, not a work order: build each item when
its absence costs you something ([1.6](01-sizing-to-the-project.md)).

Sizing follows the same rubric as the AGENTS.md decision table in
[5.2](05-context-docs.md): count non-hidden, non-vendor files, all of them, and
source-bearing top-level directories ("domains").

**Rules**

- Treat your tier's list as a ceiling, not a work order: create each item, and anything beyond it, when its absence has cost you something (1.6)
- Tier by files, domains, contributors or lifespan, whichever is highest; Tier 1 is a README, `.gitignore`, and secret scanning if it will ever be pushed (1.1–1.3)

### 1.1 Tier 1 - small (< 15 files, < 3 domains, solo, short-lived)

A script, a spike, a one-off tool. Almost everything below is overhead here.

- [ ] `README.md` - what it is, how to run it, known limits
- [ ] `.gitignore` (secrets, cache, IDE files)
- [ ] `.env.example` if it reads any env var at all
- [ ] Pre-commit secret scanning if the repo will ever be pushed anywhere

No AGENTS.md, no handover, no `designs/` doc, no `ta/`: 8.1's interview is a few lines in chat
and the intent goes in the commit message ([25.10](25-shipping.md)). If it outgrows this, promote it.

### 1.2 Tier 2 - standard (15–50 files, or 3–5 domains, or more than one contributor/agent)

The common case. Everything in Tier 1, plus:

- [ ] Project structure matches Interface / Engine / Features
- [ ] Root `AGENTS.md` - purpose, ownership, global rules, negative constraints, verification
- [ ] `scripts/setup.sh` - fresh clone to working state in one command
- [ ] `config/` for externalized configurables (patterns, prompts, thresholds)
- [ ] `designs/` - populated when a feature spans 3+ methods or touches the schema
- [ ] `test-plan.md` - numbered cases with pass criteria and prerequisites
- [ ] A decision log - every skipped/rejected item gets a dated reason and a permanent
      number. Copy `config/feature-tracker.template.md`
- [ ] A documentation update matrix - change class to the files it drags. Copy
      `config/doc-update-matrix.template.md`; walk it before each commit
- [ ] Pre-push hook running the suite - copy `config/pre-push-verify.sh`. Once more than one
      agent commits, a gate that depends on remembering to run it will eventually be skipped

### 1.3 Tier 3 - large (50+ files, or 5+ domains, or long-lived with rotating agents)

Everything in Tier 2, plus the coordination layer:

- [ ] Child `AGENTS.md` per domain folder, with a Child Docs Index in each parent
- [ ] `docs/context-index.md` - flat `File | Domain | When to use` lookup table
- [ ] `areas/<domain>-structure.md` ([5.6](05-context-docs.md)) - only for a domain whose files and
      connections a child `AGENTS.md` cannot carry; most domains never need one
- [ ] `handover.md` - the sections in [27](27-handover.md); updated after every significant session
- [ ] `testing-guide.md` - how to run tests, how to write one, pre-commit checklist
- [ ] `ta/` (+ `ta/done/`, `ta/tldr/`) for task assignments
- [ ] Subagent registry table in `AGENTS.md` or `docs/agents.md`
- [ ] Session tracking file (`sessions.txt` or equivalent)
- [ ] Audit report per milestone (`AUDIT-YYYY-MM-DD.md`)
- [ ] A review protocol the reviewing agent reads - evidence rules, gates, findings shape
      ([33](33-running-a-review.md), [34](34-findings-log.md))
- [ ] A backlog for findings filed but not driven, headed "every line is a claim"
- [ ] Documentation-truth tests, once any documented number or path exists in more than
      one file - they are what makes "docs ship with the change" enforceable

### 1.4 Running an agent unattended?

Independent of tier. Before the first hands-off run, the project needs a written standing
protocol - scope, autonomy, effort, on-failure, a budget proxy and the one-way list - and a
stated stop condition, or the run
will need a decision at 2am and stop. See [31](31-briefing-an-unattended-run.md) and, for stop conditions,
[32.3](32-running-unattended.md).

### 1.5 Driving a small or local model?

The tiers above assume a capable model. When a ~7B–30B model is doing the work, two items move
up a tier because they bound what it must hold at once, not because the project got bigger:

- `docs/context-index.md` - promote to Tier 2. Without the map it loads everything.
- `ta/` task assignments with exact file paths - promote to Tier 2. Underspecification is
  filled by invention.

See [29](29-small-models.md) for the working-set budget and [30.3](30-handing-work-to-a-small-model.md) for what to escalate elsewhere.

### 1.6 Create an artifact when its absence has cost you something

The cost is the evidence - a lost decision, a repeated
question, an agent putting a file in the wrong place. It applies inside your tier's list as
well as beyond it. Creating all of Tier 3 on day one of a
Tier 1 project is the most common way this strategy gets abandoned.

### 1.7 When a project goes quiet

Projects rarely end; they stop being touched, which is why a closing *protocol* keyed on
"finished" never fires. Treat it as a trigger instead - **the next time you open a repo whose
last commit is months old (`git log -1 --format=%cd`), before doing anything else**, spend ten minutes harvesting it:

- What did this teach you that is not written in any strategy doc? File it where lessons go.
- Keep the design docs and findings logs. A release that deletes them deletes the evidence;
  what survives otherwise is the handful of findings that happened to be actioned.
- One page of what you would do differently, while you can still remember why.

Skip it for a repo that taught you nothing. The cost of not doing it is that the lessons get
reconstructed later by surveying the repo from the outside, months late and much more
expensively - which is exactly how this strategy's own backlog was built.
