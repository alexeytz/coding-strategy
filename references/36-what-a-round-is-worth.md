# 36 What a round is worth

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

How many review rounds to run, at what effort, and what no amount of reviewing will
find. This is about the round as a whole - what to do with one finding is
[35](35-verifying-findings.md).

**Rules**

- Repeat a rung before believing a clean result from it (36.1)
- Reviewers find bad lines and miss missing ones; answer a found class with a mechanical check (36.2)
- When a review does not fit one context, split it along the axis that keeps compared things together (36.3)
- Brief a reviewer with the artifact and its contract, never your verdict (36.4)
- Docs get their own audit pass against the code; a code review does not check them (36.5)

### 36.1 How many runs, at what effort level

Measured on a seeded-defect benchmark - six defects planted in one file, each a real
shape from the project's history, four effort levels x three repeats, recall scored
as a set intersection so no judgement is involved - plus eight review rounds against
the real codebase.

- **The ladder does not nest.** The cheapest level found all six planted defects on
  one run; a middling level never exceeded five in three. A cheap rung is not a
  subset of an expensive one, so "climb for coverage" is the wrong model. They are
  different draws.
- **The spread within a level is wider than the gap between most levels** - 3, 5 and
  6 out of 6 on identical input. One run at any level tells you almost nothing.
  **Repeat a rung before believing a clean result from it.**
- **Cheap is productive, not merely adequate.** Seven rounds at the cheapest level
  found a genuine unauthenticated cross-profile write, four divergent call sites of
  one sweep, an unfenced replay path and a registration that mapped writes nowhere -
  at roughly an eighth of the top rung's wall clock. Run it for volume, early.
- **The top rung finds a different kind of defect** - class completions that require
  holding four or five call sites in mind at once, which had survived seven cheap
  rounds - and it marked three of its own findings unverified, naming the half it
  could not check. No cheap round did that.
- **The signal to climb is not a quiet round.** It is the cheap rung starting to
  file non-findings: "X is not validated" where neither side validates, or a
  self-refuting Critical. A rung reaching for material is done, whatever its count
  says. Repeated rounds at the cheap level produced 20, 7, 13, 9, 34, 33, 19
  findings on a tree being fixed between each - so "repeat until quiet" is not a
  stopping rule.
- **Only the top rung separated** on the benchmark (0.94 recall against 0.78/0.83/
  0.72). The middle levels cost multiples of the cheapest for recall inside its
  noise. If you climb, climb past them.
- **Silence closes nothing.** A repeat round in one project re-filed 2 of about 15
  still-open findings and was equally silent on fixed and unfixed ones. Close a finding with a
  test that failed before the fix, not with a later round's silence.

### 36.2 What reviews reliably miss

The benchmark's clearest result: the one planted defect missed at every level -
found 5 times in 12 runs, against 9-12 for the other five - was the only one that
was **absent code rather than wrong code**, a deleted guard branch. No amount of
reasoning fixed that.

**A reviewer of any depth finds bad lines and misses missing ones.** So when a round
finds an instance of a class, the durable answer is a mechanical check comparing the
two halves - not fixing the instance and not another review round. One defect class
in that project surfaced once per release across five releases; what ended it was a
shared helper plus a test asserting that no path may build its own version of the
set. See [14](14-writing-tests.md) for the check shapes.

### 36.3 Splitting a review that does not fit

When the target does not fit the reviewer's context window, **split along the axis
that keeps together the things that must be compared.** One project's hand-written
scopes measured 268k tokens for a single scope; splitting per *file* would have
separated the two front ends whose divergence the review exists to find. Splitting
per *action* - one handler, its twin on the other surface, and the backend functions
they call, as line ranges - fit in four bundles and kept the comparison intact.

Generate the bundles with a script, and add a test that fails if the splitter stops
resolving its inputs. Otherwise it silently emits a review that covers half the code
and looks complete.

### 36.4 Briefing the reviewer

Hand a reviewer the artifact and the contract it must meet - the diff, the spec, the
invariants - and never your verdict or the reasoning behind it. A reviewer told "this is
thread-safe" checks that it is thread-safe, and finds what confirms it; one told what the
code must do finds where it does not. The same holds when the reviewer is you in a fresh
session: write the brief before rereading your own notes. Prior art: addyosmani/agent-skills'
doubt-driven skill.

### 36.5 A doc audit is its own review

A code review reads the docs as context and checks the code. In one project fourteen code
review rounds passed 42 places where a doc and the code disagreed, which one audit of the docs
against the code then found; the worst was a wrong formula in a contract other programs read.
Run the doc audit as a separate pass with its own brief: every claim, number, formula and
example in the docs checked against what the code does. Whatever it finds that a machine could
check goes into the doc checks ([16.5](16-checking-what-you-claim.md)), as 36.2 says of any
class a review finds.
