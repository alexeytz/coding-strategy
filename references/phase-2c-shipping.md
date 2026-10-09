# Phase 2c: Shipping

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-decision-records.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [3g](phase-3g-verifying-against-real-targets.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) · [11](phase-11-debugging.md) — full names in [SKILL.md](../SKILL.md)

---

What has to be true before a change leaves your working tree: the commit message, the docs
that move with it, and the discipline around what the main branch is allowed to become.
Deciding what to build and recording what you declined is
[2b](phase-2b-decision-records.md).

### 6. Commit Conventions + Docs-First

**Types:**
- `feat:` — new feature or behavioral change
- `fix:` — bug fix (reference the bug: "fix: X -> Y (BUG #N)")
- `docs:` — documentation changes
- `test:` — test additions or changes
- `clean:` — code cleanup (removed debug, refactored, no behavior change)

**Docs-first rule:** every behavioral change ships with its documentation update — in the
same commit, or in the next commit before any further code lands. Handover, README, and the
nearest owning `AGENTS.md` are the usual targets.

Don't track this as a commit-count ratio (docs commits >= code commits): the ratio is trivially
satisfied by splitting one doc edit into three commits, which tells you nothing. The check is
whether documentation is stale, not how many commits touched it.

**A mechanical reformat records itself.** A `clean:` commit touching more files than a human
would read destroys `blame` for every line it moved. Append its SHA to a blame-ignore file in
the same commit, so the next person looking for why a line exists finds the change that made
it rather than the sweep that reindented it. Small win, honestly: it is VCS-specific, invisible
until someone runs blame, and needs local config to take effect — so also say in the commit
message that the diff is mechanical.

**Push to the remote you were given, and no other.** Do not add, rename or retarget a remote,
do not create a repository on a hosting service, and do not push to a host that is not already
in this repo's configuration. Where the code is allowed to live is a custody decision the
operator makes with information you do not have (`../operator-guide.md`), and it is decided
once per project rather than per commit. The failure this prevents is specific and one-way: an
agent being helpful with a repo-create command and publishing a private codebase, which no
later commit undoes.

If a push has nowhere to go, that is a question, not a problem to solve — the same shape as a
contradictory task assignment ([phase 2a §4](phase-2a-designing-a-change.md)). Whether you may
push at all, and on what cadence, is the Autonomy field of the standing protocol
([phase 8a §22](phase-8a-unattended-runs.md)); this rule is about *where*, that one is about
*whether*.

#### The pre-commit sweep

"Docs ship with the change" is not actionable on its own, because the docs that go stale are
the ones nobody remembered were downstream of the edit. Keep a **documentation update
matrix** — change class in one column, the files it drags in the other — and walk it before
every commit. Copy `config/doc-update-matrix.template.md`.

Four steps, in order: run the doc-truth checks ([phase 3d §10](phase-3d-checking-what-you-claim.md));
read `git diff --cached --name-only` against the matrix and open the targets for every class
present; **write the changelog entry now rather than at release time**, because the reasoning
is in your head today and a changelog reconstructed at tag time records what changed and
loses why; fix what drifted in the same commit, since a follow-up commit is a promise and the
docs that rot are the ones whose follow-up never came.

Two rules keep the matrix from becoming ceremony. **Add a row the first time a doc goes stale
for a reason not already listed** — every row should trace to something that actually
drifted, which is what makes it a postmortem list rather than a wish list. And **when a row's
drift recurs, delete the row and write a check**: a matrix is the fallback for what cannot be
automated, and a rule enforced only by a human reading a table drifts at the same rate as the
docs it guards.

**The main branch only ever advances on verified work.** Suites green *before* the push or merge
that moves it, never after — the same rule [phase 9 §24](phase-9-releasing.md) applies to a tag,
for the same reason. The point is not commit hygiene but keeping one ref that is known good:
[phase 4 §13](phase-4-quality-gates.md) requires every grader to carry a known-good reference,
and main *is* that reference for the repository. Once it is only probably green you have lost the
thing you fall back to.

**The gated event is the push or merge, not the commit.** Commit freely on a branch — to
preserve work before building on it, to mark a point you may return to. That is what branches
are for and it costs nothing. **So if you plan several commits before you can verify them, branch
first**: deciding that before the first commit is free, deciding it after the third is a rebase.

Gate it mechanically or it drifts — `config/pre-push-verify.sh` is the shipped one, plus branch
protection for what a local hook cannot enforce ([phase 3f §12](phase-3f-numbers-you-can-publish.md): local guards catch
accidents, not a determined author). Do **not** gate every local commit on a slow suite;
[phase 3e §11](phase-3e-pre-commit-security.md) records where that goes — a check that fires on every
commit teaches an operator to pass `--no-verify`, and then nothing is gated at all.

**The operator can override this, and on a public remote you warn first.** It is their repository;
an instruction to push unverified work to main is a decision they are entitled to make, and you
follow it. On a **private** remote, follow it and say nothing further. On a **public** one, warn
once before the push — naming what is unverified and what the fallback ref now is — then proceed.
The asymmetry is the one [phase 3e §11](phase-3e-pre-commit-security.md) already prices for
secrets: a public ref is copied within minutes by clones, forks, mirrors and other people's CI, so
it cannot be un-published. Warn **once**. A second objection to a reaffirmed instruction is not
diligence, it is refusing the operator's call in slow motion.

**Beyond that one rule, branch strategy is a project decision. Common options:**
- Single branch (`main`) — linear history, fast iteration; the rule above is the whole discipline
- `main` + `dev` — stable/unstable separation, safer for collaborators
- Gitflow — overkill for solo/small projects
