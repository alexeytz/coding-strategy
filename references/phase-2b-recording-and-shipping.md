# Phase 2b: Recording & shipping

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Where a decision is written down so it is not re-litigated, and what has to be true
before the commit lands. Designing the change in the first place is
[2a](phase-2a-designing-a-change.md).

### 5. Decision Records

One file — `consider-features.md`, `proposed_features.md`, any name — holding every feature
idea with a dated decision. Copy `config/feature-tracker.template.md`; it carries the status
legend and the maintenance rules.

**Statuses:** DONE, BACKLOG, CONSIDER LATER, COVERED BY #N, WON'T IMPLEMENT, SKIP.

```
### #N. Feature name ❌ WON'T IMPLEMENT
Two or three sentences on what the idea is.
**Decision (YYYY-MM-DD):** The verdict, then why — what was considered and rejected.
**Design doc:** designs/<name>.md, or `git show <sha>^:designs/<name>.md` if deleted.
```

**Why:** it stops decisions being re-litigated. A future agent shouldn't wonder "why didn't we
do X?" — and worse, a review will eventually propose X as a finding, so the answer needs to be
somewhere a reviewer's intent gate ([phase 7a](phase-7a-running-a-review.md)) will find it.

Two rules are worth stating here because getting them wrong is expensive later; the rest
are in the template. **The number is a permanent identifier** — commits, findings and other
docs cite `#37`, so never renumber and never reuse after a delete. And **every entry ends in a
dated decision, including the open ones**: "no decision yet, as of YYYY-MM-DD" is a record, a
bare description is what rots.

#### Patches over someone else's tree are a record too

If the project carries local changes on a vendored or forked dependency, they need the same
treatment as a decision, and the ledger is what stops a patch outliving its reason. Each local
change is a patch file plus a row naming the upstream issue or PR, the base commit it applies to,
why it exists, and — the field that does the work — **its removal condition and the command that
verifies it**: "remove when the vendored source contains upstream PR #12907 and the resize tests
pass without this patch." A patch with no removal condition is not a patch, it is a permanent
fork, and should be named one.

Close it mechanically in both directions, because this is the record that decays exactly when it
matters most — when nobody is watching upstream any more. Two ordinary tests do it: every patch
file appears in the ledger, and each one reverse-applies against the tree, which proves it is
*currently applied* rather than merely filed. The prose half of the ledger — who last looked
upstream and why they did not rebase — is worth writing and will rot; the two tests will not.

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
([phase 8a §19](phase-8a-unattended-runs.md)); this rule is about *where*, that one is about
*whether*.

#### The pre-commit sweep

"Docs ship with the change" is not actionable on its own, because the docs that go stale are
the ones nobody remembered were downstream of the edit. Keep a **documentation update
matrix** — change class in one column, the files it drags in the other — and walk it before
every commit. Copy `config/doc-update-matrix.template.md`.

Four steps, in order: run the doc-truth checks ([phase 3b §9](phase-3b-verifying.md));
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

**Branch strategy is a project decision, not a rule. Common options:**
- Single branch (`main`) — linear history, fast iteration, no merge conflicts
- `main` + `dev` — stable/unstable separation, safer for collaborators
- Gitflow — overkill for solo/small projects
