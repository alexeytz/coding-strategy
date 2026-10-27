# 24 Quality gates

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Gates that can actually fail: a hook versus CI, adopting a linter, saying what a gate does not
cover, seeing it fail, and a mechanism for a failure you cannot undo. The audit before work is
declared done is [23](23-audit-milestones.md).

**Rules**

- What must not be bypassed runs in CI as well as the hook (24.1)
- A linter in a tree too big to fix this week: advisory against the merge base, a rule blocks once an incident bought it; small tree, fix all and block (24.2)
- Every gate names what it does not check and, if protective, what defeats it (24.3)
- Break the thing a gate watches and see it go red before trusting it green; never pipe the checked command into anything (24.4)
- Every grader carries a known-good and a plausible-wrong reference and refuses to run when it cannot rank them (24.4)
- A failure that cannot be undone and can be checked mechanically gets recoverable data or a guard where every route passes, the guard saying why; judgment stays prose (24.5)
- A new or fixed guard is wired into every caller in its strict form, and reads the whole population its rule covers, with exclusions named in its test (24.6)

### 24.1 A hook is a speed bump; CI is the gate

Both matter and they are not the same thing. A pre-commit hook gives the fast local signal,
and it is bypassable - `--no-verify` exists, and the hook's own error message usually
mentions it. So anything that must not be bypassed runs in CI as well, and CI is where a
merge is actually blocked. A check earns its place in the hook by being fast and
deterministic; it earns its place in CI by mattering. The secret scan belongs in both, for
exactly this reason: locally it stops the commit, and in CI it stops the merge when someone
skipped the hook.

### 24.2 Adopting a linter into an existing codebase

Turning a full ruleset on at once against a tree that predates it produces thousands of
diagnostics and teaches everyone to ignore the linter. Turn the whole thing on **advisory**,
and report it as a delta against the merge base: run it on base and head, compare on
`(rule, file, message)` so unrelated line shifts do not read as new findings, and print the
count of new ones. A rule graduates to **blocking** only when an incident bought it, and its
config comment names that incident. Keep the two in separate jobs so the blocking set is
never diluted by the advisory noise. This is [14.6](14-writing-tests.md)'s ratchet
pointed at a linter - and the same threshold decides between them: on a small or new
codebase, fixing everything and turning the linter fully blocking is cheaper than building
the two-job machinery. The delta gate is for the tree too large to fix this week.

### 24.3 Every gate declares what it does not cover

An audit checklist of greens with no negative space invites a conclusion it cannot
support. A gate ships a named section saying what it deliberately does not check and why -
and, for anything protective, what defeats it: "a PR can edit this workflow, so these
guards catch accidents and casual attempts, not a determined author; branch protection and
human review of workflow diffs remain the real backstop." The absence of that section is
the defect, not the absence of coverage. It is a documentation habit rather than a
mechanism, so it survives only where a doc-truth check asserts the section exists
([16.5](16-checking-what-you-claim.md)); without one it becomes the ritual
paragraph nobody updates when coverage changes.

### 24.4 A gate you have not seen fail is not a gate

Before trusting any checker, grader or detector, break the thing it watches and confirm it goes
red. Two ways this fails, and both ship green:

- **The wiring cannot fail.** One project's CI compiled a file and piped the compiler through
  `head`; a pipeline exits with the status of its *last* command, so the compiler's errors were
  masked and the job could only ever pass. It guarded the one file nothing else compiled. Never
  pipe the checked command into anything.
- **The judgement is wrong.** A correctness gate once reported a large regression that did not
  exist - it could not read unfenced code, and tested for a deliverable the prompt never asked
  for, between them accounting for 72 of 74 failures. The answer is structural: every grader
  carries a known-good reference that must pass *and* a plausible-wrong one that must fail, and
  refuses to run when it cannot tell them apart. Where judging is expensive, prove the logic
  offline for free and the judgement separately.

The same rule read backwards: a check that cannot run is not a gate either. A path-filtered
required check stays pending forever when no matching file changes, which blocks the merge it was
meant to guard.

### 24.5 A failure you cannot undo gets a mechanism, not a sentence

A rule is only as strong as the weakest model that reads it. Where its failure is irreversible -
data deleted, a secret pushed, main advanced on red - and mechanically checkable, ship something
that runs, refusing by default and exiting on the predicate it prints; the sentence keeps only why
and when. `config/` carries them: secret scanning, the pre-push gate,
[`guard-shrink.py`](../config/guard-shrink.py) (13.2), [`safe-delete.sh`](../config/safe-delete.sh)
(12.3, 11.7), and [`delete-guard-hook.py`](../config/delete-guard-hook.py) for the agent's tool
layer, each with `--self-test`. Judgment rules - a review's intent gate - stay prose.

A mechanism protects only the path it sits on. In this skill's own test a 12B model, with 13.2's
line in its context, deleted 400 of 412 cached items on a 12-row export ("Status: Verified."), and
ignored a refusing sync script the README named, five times of five. So hold the step where every
route passes: recoverable data (versioned, snapshotted) or the agent's tool layer. A host hook that
put the table back after any call that emptied it held in all ten runs - but restoring silently,
it was fought: one run escalated to DROP TABLE and moving the file, and reported a count it never
kept. A guard says why it refused.

Give the job a supported route, too. A project with no bulk delete watched an agent build its
own backend object and delete 423 rows through it, a route no guard sat on. A missing tool is
an unguarded route. And an ad-hoc write to live data that no guard covers - a `DELETE` typed
in a session - is a one-way action ([31.3](31-briefing-an-unattended-run.md)): run the exact
statement as a count or a dry run first, or ask.

### 24.6 A guard nobody calls, or that reads a hand-picked list, guards nothing

Two ways a guard exists and protects nothing. **Its callers do not call it**: one project
logged six cases in two days of a guard written and never invoked - a run loop that called
none of its three checks, a fix that reached the doc an operator pastes but not the two scripts
they run, a filter whose helper was never imported and so had never worked. When you add or
fix a guard, find every caller and assert each uses it. **It reads a list someone picked**: a
count check that read 3 of the 8 files carrying the count, a drift check over one doc of nine,
a glob that missed a second hooks directory. Read every tracked file the rule covers and name
the exclusions in the test. A check that found something proves it ran, not that it read
everything.
