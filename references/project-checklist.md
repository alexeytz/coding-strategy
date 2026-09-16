# New-project checklist

Scale the ceremony to the project. Every artifact below costs time to create and, worse, time
to keep true — a stale `handover.md` is more harmful than no `handover.md`. Pick the tier that
matches what you're building, then work down the list.

Sizing follows the same rubric as the AGENTS.md decision table in
`phase-5a-context-docs.md`: count non-vendor source files and source-bearing top-level
directories ("domains").

## Tier 1 — small (< 15 files, < 3 domains, solo, short-lived)

A script, a spike, a one-off tool. Almost everything below is overhead here.

- [ ] `README.md` — what it is, how to run it, known limits
- [ ] `.gitignore` (secrets, cache, IDE files)
- [ ] `.env.example` if it reads any env var at all
- [ ] Pre-commit secret scanning if the repo will ever be pushed anywhere

No AGENTS.md, no handover, no design docs, no `ta/`. If it outgrows this, promote it.

## Tier 2 — standard (15–50 files, or 3–5 domains, or more than one contributor/agent)

The common case. Everything in Tier 1, plus:

- [ ] Project structure matches Interface / Engine / Features
- [ ] Root `AGENTS.md` — purpose, ownership, global rules, negative constraints, verification
- [ ] `scripts/setup.sh` — fresh clone to working state in one command
- [ ] `config/` for externalized configurables (patterns, prompts, thresholds)
- [ ] `designs/` — populated when a feature spans 3+ methods or touches the schema
- [ ] `test-plan.md` — numbered cases with pass criteria and prerequisites
- [ ] A decision log — every skipped/rejected item gets a dated reason and a permanent
      number. Copy `config/feature-tracker.template.md`
- [ ] A documentation update matrix — change class to the files it drags. Copy
      `config/doc-update-matrix.template.md`; walk it before each commit

## Tier 3 — large (50+ files, or 5+ domains, or long-lived with rotating agents)

Everything in Tier 2, plus the coordination layer:

- [ ] Child `AGENTS.md` per domain folder, with a Child DOX Index in each parent
- [ ] `docs/context-index.md` — flat `File | Domain | When to use` lookup table
- [ ] `handover.md` — load order, current state, remaining work; updated per session
- [ ] `testing-guide.md` — how to run tests, how to write one, pre-commit checklist
- [ ] `ta/` (+ `ta/done/`, `ta/tldr/`) for task assignments
- [ ] Subagent registry table in `AGENTS.md` or `docs/agents.md`
- [ ] Session tracking file (`sessions.txt` or equivalent)
- [ ] Audit report per milestone (`AUDIT-YYYY-MM-DD.md`)
- [ ] A review protocol the reviewing agent reads — evidence rules, gates, findings shape
      (`phase-7a-running-a-review.md`, `phase-7b-findings-log.md`)
- [ ] A backlog for findings filed but not driven, headed "every line is a claim"
- [ ] Documentation-truth tests, once any documented number or path exists in more than
      one file — they are what makes "docs ship with the change" enforceable

## Running an agent unattended?

Independent of tier. Before the first hands-off run, the project needs a written standing
protocol — scope, autonomy, effort, on-failure — and a stated stop condition, or the run
will need a decision at 2am and stop. See `phase-8a-unattended-runs.md`.

## Driving a small or local model?

The tiers above assume a capable model. When a ~7B–30B model is doing the work, two items move
up a tier because they bound what it must hold at once, not because the project got bigger:

- `docs/context-index.md` — promote to Tier 2. Without the map it loads everything.
- `ta/` task assignments with exact file paths — promote to Tier 2. Underspecification is
  filled by invention.

See `small-model-operation.md` for the working-set budget and what to escalate elsewhere.

## Rule

Create an artifact when its absence has cost you something — a lost decision, a repeated
question, an agent putting a file in the wrong place. Creating all of Tier 3 on day one of a
Tier 1 project is the most common way this strategy gets abandoned.

## When a project goes quiet

Projects rarely end; they stop being touched, which is why a closing *protocol* keyed on
"finished" never fires. Treat it as a trigger instead — **the next time you open a repo you
have not touched in months, before doing anything else**, spend ten minutes harvesting it:

- What did this teach you that is not written in any strategy doc? File it where lessons go.
- Keep the design docs and findings logs. A release that deletes them deletes the evidence;
  what survives otherwise is the handful of findings that happened to be actioned.
- One page of what you would do differently, while you can still remember why.

Skip it for a repo that taught you nothing. The cost of not doing it is that the lessons get
reconstructed later by surveying the repo from the outside, months late and much more
expensively — which is exactly how this strategy's own backlog was built.
