# Phase 7d: What a round is worth

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

How many review rounds to run, at what effort, and what no amount of reviewing will
find. This is about the round as a whole — what to do with one finding is
[7c](phase-7c-verifying-findings.md).

### How many runs, at what effort level

Measured on a seeded-defect benchmark — six defects planted in one file, each a real
shape from the project's history, four effort levels x three repeats, recall scored
as a set intersection so no judgement is involved — plus eight review rounds against
the real codebase.

- **The ladder does not nest.** The cheapest level found all six planted defects on
  one run; a middling level never exceeded five in three. A cheap rung is not a
  subset of an expensive one, so "climb for coverage" is the wrong model. They are
  different draws.
- **The spread within a level is wider than the gap between most levels** — 3, 5 and
  6 out of 6 on identical input. One run at any level tells you almost nothing.
  **Repeat a rung before believing a clean result from it.**
- **Cheap is productive, not merely adequate.** Seven rounds at the cheapest level
  found a genuine unauthenticated cross-profile write, four divergent call sites of
  one sweep, an unfenced replay path and a registration that mapped writes nowhere —
  at roughly an eighth of the top rung's wall clock. Run it for volume, early.
- **The top rung finds a different kind of defect** — class completions that require
  holding four or five call sites in mind at once, which had survived seven cheap
  rounds — and it marked three of its own findings unverified, naming the half it
  could not check. No cheap round did that.
- **The signal to climb is not a quiet round.** It is the cheap rung starting to
  file non-findings: "X is not validated" where neither side validates, or a
  self-refuting Critical. A rung reaching for material is done, whatever its count
  says. Repeated rounds at the cheap level produced 20, 7, 13, 9, 34, 33, 19
  findings on a tree being fixed between each — so "repeat until quiet" is not a
  stopping rule.
- **Only the top rung separated** on the benchmark (0.94 recall against 0.78/0.83/
  0.72). The middle levels cost multiples of the cheapest for recall inside its
  noise. If you climb, climb past them.

### What reviews reliably miss

The benchmark's clearest result: the one planted defect missed at every level —
found 5 times in 12 runs, against 9-12 for the other five — was the only one that
was **absent code rather than wrong code**, a deleted guard branch. No amount of
reasoning fixed that.

**A reviewer of any depth finds bad lines and misses missing ones.** So when a round
finds an instance of a class, the durable answer is a mechanical check comparing the
two halves — not fixing the instance and not another review round. One defect class
in that project surfaced once per release across five releases; what ended it was a
shared helper plus a test asserting that no path may build its own version of the
set. See [phase 3b §8](phase-3b-verifying.md) for the check shapes.

### Splitting a review that does not fit

When the target does not fit the reviewer's context window, **split along the axis
that keeps together the things that must be compared.** One project's hand-written
scopes measured 268k tokens for a single scope; splitting per *file* would have
separated the two front ends whose divergence the review exists to find. Splitting
per *action* — one handler, its twin on the other surface, and the backend functions
they call, as line ranges — fit in four bundles and kept the comparison intact.

Generate the bundles with a script, and add a test that fails if the splitter stops
resolving its inputs. Otherwise it silently emits a review that covers half the code
and looks complete.
