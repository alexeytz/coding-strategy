# coding-strategy

Language-agnostic patterns for running a software project with coding agents - structure,
design docs, resilience, testing, reviews, unattended runs, releases, data architecture.

It ships **documentation, not code**. The product is [`SKILL.md`](SKILL.md) and the files it
routes to.

## The idea

Most strategy documents fail the same way: they grow until nobody loads them, and then nobody
follows them. This one is a **routing table**. You never load the whole strategy - `SKILL.md`
maps a trigger ("about to commit", "auditing code you did not write", "running for hours with
nobody watching") to exactly one file, and that file is one job, sized to be loaded on its own.

Every rule is numbered `N.M` and lives in exactly one numbered file, and a test asserts it - along
with the routing table matching what is on disk, and no file exceeding the budget that makes it
loadable.

## Using it

**As a skill.** Clone it into the directory your agent runner reads skills from, as a folder
named `coding-strategy` - for example `~/.claude/skills/` for Claude Code, `~/.pi/agent/skills/`
for Pi; your runner's docs name its own. `SKILL.md`'s frontmatter describes when it should fire;
the routing table decides what gets read. Agents differ in how much of that description the model
sees - some show all of it, some only a short prefix or the first line, so the first line is
written to stand alone. Many agents still do not open a skill unprompted, so put this line first
in the project's `AGENTS.md` Global Rules (it is the first rule of
[`config/AGENTS.root.template.md`](config/AGENTS.root.template.md)):

```
- Load the `coding-strategy` skill before the first edit of a session, and read the file its `SKILL.md` routes you to for the task (5.9)
```

With it, OpenCode, Pi, Hermes and oh-my-pi opened the skill in every run tested.

**By hand.** Open [`SKILL.md`](SKILL.md), find the row matching what you are about to do, read
that one file.

**Under a tight context budget.** Load the one card for the work in hand -
[`references/rules-card.md`](references/rules-card.md) (building) or
[`references/rules-card-operating.md`](references/rules-card-operating.md) (everything else:
sizing, docs, delegation, review, debugging, small models, unattended runs) - instead of the files. One line per rule, no rationale,
generated from each file's own Rules block: a selection of what changes an agent's behaviour on an
ordinary task, not an index of everything.

**Driving a small or local model?** Read [`references/29-small-models.md`](references/29-small-models.md)
first. It covers why small models degrade - distractor load, constraint capacity, positional
dilution - and the working-set budget that answers it. Load `SKILL.md` and one file per job, not
both cards: on two local models the cards gave the same results and took up to 2.2 times as long
on long tasks.

## Adopting it in your project

[`config/`](config/) holds copy targets: AGENTS.md templates, a pre-commit secret-scanning hook
with a gitleaks config, a pre-push hook that refuses to advance the main branch unless the
checkout it verified is the commit being pushed, a feature tracker, a doc-update matrix, an
`.env.example`, and two guards for deletes you cannot undo. `guard-shrink.py` refuses a sync whose
source is empty, short or disjoint; `safe-delete.sh` deletes only under an allowlisted root, dry-run
first and recoverably, with its roots read from the project's `.env`; `delete-guard-hook.py`, a Claude
Code hook, refuses an agent's own `rm -rf` or `DELETE FROM` and points it at the two guards.
[`config/README.md`](config/README.md) says, for each, what problem it
solves and when you need it; most projects need few of them. Copy them, then edit the copy: they
are meant to be overwritten cleanly by a later update.

Start with [`references/01-sizing-to-the-project.md`](references/01-sizing-to-the-project.md),
which tiers the ceremony by project size. **Most projects should skip most of this.** A fifteen-file tool does
not need a findings backlog or a handover protocol, and the checklist says so.

## Why the rules have arguments attached

Every rule here came from something that broke, and most carry the incident that bought them:
the pipeline that exited with `head`'s status so a CI check could only ever pass; the secret
scanner that allowlisted `docs/`, so the same token blocked in `src/` and committed clean in
`docs/`; the pre-commit hook that blocked *every* commit because its scanner's self-update failed
before it scanned anything.

Rules without their reasons get followed until they are inconvenient, then dropped. Rules with a
paid-for example attached tend to survive contact.

Most sections also carry the argument **against** the rule. That is deliberate - a rule you
cannot argue against is one nobody finished thinking about.

## It enforces its own rules

```sh
tests/check-docs.sh              # structural checks. No network, no install.
tests/check-docs.sh --self-test  # seed a break for each guard, require it to fail
tests/build-cards.sh             # regenerate the two rules cards from the files' Rules blocks
```

The suite asserts what the strategy claims: links resolve, the routing table matches what is on
disk, every rule `N.M` exists exactly once and every citation of one lands on it, no reference
file exceeds its size budget, the cards are exactly what the files' Rules blocks generate.

`--self-test` exists because guards rot. Three of this project's own bugs were checks that had
silently stopped matching the tree - one of them reported **PASS** on input it could not parse.
A green check is not evidence until you have seen it go red.

## How it was tested

Two kinds of testing went into it: reading the text, and watching agents use it. Both ran
2026-09 to 2026-10.

**The text.** Twenty-one review rounds by outside models, each told to find what is wrong
rather than to praise. Every finding was checked against the files before anything changed. The
reviewer then saw the fixes, and it could argue a decline back, and sometimes did. The bug log
reached ninety-nine entries, most of them from these rounds: contradictions between files, rules that said less than
their Rules line, numbers that did not match the test they cited, scripts in `config/` that failed
on input nobody had tried. Each fix shipped with a case in the structural suite when the defect
could recur.

**The behaviour.** Over fifty tests and about 2,000 graded agent runs, under five coding agents
([Pi](https://github.com/earendil-works/pi), [Hermes Agent](https://github.com/NousResearch/hermes-agent),
[OpenCode](https://github.com/anomalyco/opencode), [oh-my-pi](https://github.com/can1357/oh-my-pi)
and Claude Code), with seven models from a 12B on a gaming card to a 122B and Claude Opus. Most
runs used local models served by vLLM and llama.cpp, because that is where the skill is meant to
earn its keep. The method:

- **Grade the workspace, never the reply.** Each task is a small scripted repository with one
  prompt and a mechanical grader that inspects what is left behind: the data, the commits, the
  tests. Several tasks hide a trap for an irreversible mistake, such as a sync from an export that
  stopped at 12 of 410 rows, a key in a branch already pushed, or a user's live database next to
  the code being changed. Critical checks decide the verdict, and soft checks (did it say why,
  did the tests still pass) are recorded beside it.
- **Compare arms on the same day, on the same endpoint.** With and without the skill, with the
  whole skill or one card, with the skill installed or preloaded. A run is void, not failed, when
  the model behind the endpoint changed or the agent updated itself mid-run. Both are checked
  before and after every run.
- **Isolate every run.** Each agent runs in a sandbox with a fresh home and only this skill
  installed. It cannot see the graders, the other runs or the user's files, and it runs in its
  own memory scope. Paths name nothing being measured: agents show the model their working
  directory, and a path that says "eval" tells it what is going on.
- **Ask, then check the answer.** After each task the agent is asked whether it used the skill,
  which files it opened and why. Every file it names is checked against the files it actually
  opened.

What it found, in short:

- **Whether the skill gets loaded at all depends on the agent more than the model.** One agent,
  run one-shot, tells the model not to load process skills for work it already knows, and the
  skill was loaded 4 times in 32. The same agent run interactively loaded it 28 times in 32.
  The one-line `AGENTS.md` above took the operator's daily 27B model from opening the skill in 0
  of 50 runs to 50 of 50.
- **Strong models pass the short tasks without it.** There, the skill mostly changes process: a
  test and a commit after every item, findings written down, at a cost in time and tokens. For a
  27B model, `SKILL.md` alone took a task with a live database from 5 passes in 10 to 9.
- **The process pays off in the next session.** A fresh session continuing a list finished
  correctly in 15 of 15 pairs whose first session had the skill, against 11 of 15 without it.
  The difference was what the first session left behind: commits naming what the diff could not
  show, rather than an uncommitted tree the next session undid.
- **Every model that destroyed data reported the job as verified.** Hence the rules that treat
  an agent's report as a lead and the diff as the evidence.
- **Results changed the skill.** Rules were added where a test showed a gap: committing each
  finished step ([25.10](references/25-shipping.md)), what a delegation brief must carry
  ([28.5](references/28-delegating.md)), a verifier for a hand-off nobody will read
  ([28.6](references/28-delegating.md)), and a mechanism for a failure that cannot be undone
  ([24.5](references/24-quality-gates.md)).

The same graded tasks now ship in [llm-assay](https://github.com/alexeytz/llm-assay), a separate
tool for testing LLM endpoints and coding agents. It runs them against any OpenAI-compatible endpoint under Pi,
Hermes, OpenCode or oh-my-pi, and checks each request on the wire against the settings it pinned.
It also does `llama-bench`-style speed measurement at real context depths, with paired A/B
significance tests, and a long-context quality probe. The test logs for this skill stay in the
development repository.

## Honest limits

- **Extracted, not derived.** These patterns come from real projects, so they carry those
  projects' shapes. Multi-service and polyrepo layout is
  [deliberately out of scope](references/37-reference.md), with the reason.
- **The suite tests the documents, not the behaviour.** That is the next section's job, and
  its results are mixed in the ways described there.
- **A rule in context does not stop a model that will not apply it.** On five tasks built around
  the skill's rules for irreversible failures - a sync from a truncated export, a pushed key -
  the two stronger local models passed 98 of 100 runs, with or without the skill, and
  three weaker ones failed the data tasks every time - with the skill loaded, and one of them
  with the rule's own line in its context. A refusing script the project's README named was
  never used; a guard at the agent's tool layer kept the data in every run, and when it said why
  it had refused, the model stopped and asked instead of fighting it. Every model that deleted
  live data unguarded reported the job verified. Hence [24.5](references/24-quality-gates.md): a failure you cannot undo gets a
  mechanism on every route, not a sentence.
- **Not dogma.** `SKILL.md` says so up front. Scale it down - the checklist tells
  you where - and adapt it to your own model, tools and team. Record each deliberate deviation
  in the project's `AGENTS.md` (the template has a slot), so the next session does not undo it.

## Repository map

| Path | What |
|---|---|
| [`SKILL.md`](SKILL.md) | The routing table. This is the product |
| [`references/`](references/) | The 37 numbered files, one job each, in workflow order, and the two generated rules cards |
| [`config/`](config/) | Copy targets for projects adopting this: templates, two git hooks, two guards for deletes and a hook that routes an agent to them; [`config/README.md`](config/README.md) says what each is for and when you need it |
| [`operator-guide.md`](operator-guide.md) | The human's half: quota, tool routing, hosting custody, decisions an agent must not make alone |
| [`tests/`](tests/) | The structural suite and the card generator that keep the above honest. They check the skill, not your project ([`tests/README.md`](tests/README.md)) |

Development of this skill - design docs, the backlog of lessons harvested from other projects,
the bug log, and session handovers - lives in a separate repository. This one carries the skill.

## Licence

MIT - see [LICENSE](LICENSE).

Rules in this skill are illustrated with incidents observed in real projects. Where a file
quotes or cites an outside project, it is cited as prior art and attributed by name - not
endorsed by, nor affiliated with, this project.
