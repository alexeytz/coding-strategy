# 25 Shipping

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

What has to be true before a change leaves your working tree: the commit message, the docs
that move with it, and the discipline around what the main branch is allowed to become.
Deciding what to build and recording what you declined is
[10](10-decision-records.md).

**Rules**

- Commit types: `feat` `fix` `docs` `test` `clean` (25.1)
- Every behavioural change ships its doc update in the same commit, or the next one before more code lands (25.2)
- A mechanical sweep too large to read says so in its message, and its SHA goes in `.git-blame-ignore-revs` in the next commit (25.3)
- Push only to the remote you were given; never add, retarget or create one (25.4)
- Before committing, walk the doc-update matrix against the staged diff and write the changelog entry; a row whose drift recurs becomes a check (25.5)
- Main only advances on green: gate the push or merge, never every commit on a slow suite; several commits before verifying means branch first (25.6, 25.7)
- The operator may order unverified work pushed to main; on a public remote, warn once first (25.8)
- Commit each step once it works; the message carries what the diff cannot show - an operator's fact, a decision, what was left alone on purpose (25.10)

### 25.1 Commit types

- `feat:` - new feature or behavioral change
- `fix:` - bug fix (reference the bug: "fix: X -> Y (BUG #N)")
- `docs:` - documentation changes
- `test:` - test additions or changes
- `clean:` - code cleanup (removed debug, refactored, no behavior change)

### 25.2 Docs ship with the change

Every behavioral change ships with its documentation update - in the
same commit, or in the next commit before any further code lands. Handover, README, and the
nearest owning `AGENTS.md` are the usual targets.

Don't track this as a commit-count ratio (docs commits >= code commits): the ratio is trivially
satisfied by splitting one doc edit into three commits, which tells you nothing. The check is
whether documentation is stale, not how many commits touched it.

### 25.3 A mechanical reformat records itself

A `clean:` commit touching more files than a human
would read destroys `blame` for every line it moved. Append its SHA to `.git-blame-ignore-revs` in
the commit right after it - a commit cannot hold its own SHA - so the next person looking for why a line exists finds the change that made
it rather than the sweep that reindented it. Small win, honestly: it is VCS-specific, invisible
until someone runs blame, and needs local config to take effect (`git config blame.ignoreRevsFile .git-blame-ignore-revs`) - so also say in the commit
message that the diff is mechanical.

### 25.4 Push to the remote you were given, and no other

Do not add, rename or retarget a remote,
do not create a repository on a hosting service, and do not push to a host that is not already
in this repo's configuration. Where the code is allowed to live is a custody decision the
operator makes with information you do not have (`../operator-guide.md`), and it is decided
once per project rather than per commit. The failure this prevents is specific and one-way: an
agent being helpful with a repo-create command and publishing a private codebase, which no
later commit undoes.

If a push has nowhere to go, that is a question, not a problem to solve - the same shape as a
contradictory task assignment ([9.7](09-task-assignments.md)). Whether you may
push at all is the Autonomy field of the standing protocol
([31.1](31-briefing-an-unattended-run.md)); this rule is about *where*, that one is about
*whether*.

### 25.5 The pre-commit sweep

"Docs ship with the change" is not actionable on its own, because the docs that go stale are
the ones nobody remembered were downstream of the edit. Keep a **documentation update
matrix** - change class in one column, the files it drags in the other - and walk it before
every commit. Copy `config/doc-update-matrix.template.md`.

Four steps, in order: run the doc-truth checks ([16.5](16-checking-what-you-claim.md));
read `git diff --cached --name-only` against the matrix and open the targets for every class
present; **write the changelog entry now rather than at release time**, because the reasoning
is in your head today and a changelog reconstructed at tag time records what changed and
loses why; fix what drifted in the same commit, since a follow-up commit is a promise and the
docs that rot are the ones whose follow-up never came.

Two rules keep the matrix from becoming ceremony. **Add a row the first time a doc goes stale
for a reason not already listed** - every row should trace to something that actually
drifted, which is what makes it a postmortem list rather than a wish list. And **when a row's
drift recurs, delete the row and write a check**: a matrix is the fallback for what cannot be
automated, and a rule enforced only by a human reading a table drifts at the same rate as the
docs it guards.

### 25.6 The main branch only ever advances on verified work

Suites green *before* the push or merge
that moves it, never after - the same rule [26.1](26-releasing.md) applies to a tag,
for the same reason. The point is not commit hygiene but keeping one ref that is known good:
[24.4](24-quality-gates.md) requires every grader to carry a known-good reference,
and main *is* that reference for the repository. Once it is only probably green you have lost the
thing you fall back to.

### 25.7 The gated event is the push or merge, not the commit

Commit freely on a branch - to
preserve work before building on it, to mark a point you may return to. That is what branches
are for and it costs nothing. **So if you plan several commits before you can verify them, branch
first**: deciding that before the first commit is free, deciding it after the third is a rebase.

Gate it mechanically or it drifts - `config/pre-push-verify.sh` is the shipped one, plus branch
protection for what a local hook cannot enforce ([17.8](17-numbers-you-can-publish.md): local guards catch
accidents, not a determined author). Do **not** gate every local commit on a slow suite: a
hook earns its place by being fast ([24.1](24-quality-gates.md)), and a check that
fires on every commit teaches an operator to pass `--no-verify` - the shipped secret-scan hook
records the incident - and then nothing is gated at all.

### 25.8 The operator can override this, and on a public remote you warn first

It is their repository;
an instruction to push unverified work to main is a decision they are entitled to make, and you
follow it. On a **private** remote, follow it and say nothing further. On a **public** one, warn
once before the push - naming what is unverified and what the fallback ref now is - then proceed.
The asymmetry is the one [22.3](22-secret-scanning.md) already prices for
secrets: a public ref is copied within minutes by clones, forks, mirrors and other people's CI, so
it cannot be un-published. Warn **once**. A second objection to a reaffirmed instruction is not
diligence, it is refusing the operator's call in slow motion.

### 25.9 Beyond that, branch strategy is a project decision

- Single branch (`main`) - linear history, fast iteration; 25.6 is the whole discipline
- `main` + `dev` - stable/unstable separation, safer for collaborators
- Gitflow - overkill for solo/small projects

### 25.10 Commit each finished step, with what the diff cannot show

Once a step works, commit it before
starting the next. The diff says what changed; the message carries what it cannot: a fact the
operator gave, a decision, something left alone on purpose. A later session, or this one after a
compaction, starts from `git log` and the tree. Uncommitted work with no reason reads as a
mistake there, and can be undone.
