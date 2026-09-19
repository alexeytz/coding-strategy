# Phase 7c: Verifying findings

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

What happens to a single finding after it is filed. Producing findings is
[7a](phase-7a-running-a-review.md); logging them is [7b](phase-7b-findings-log.md);
how much a whole round is worth is [7d](phase-7d-what-a-round-is-worth.md).

### 21. Verifying, refuting and dispositioning

**Verify every finding before acting on it.** Of the first four Criticals one review
loop produced, two did not reproduce. Drive the claim against the code; do not act
on a severity label.

**Verify the claim, not the label** — and that applies to the citation too. Search
the whole codebase for a quoted snippet rather than opening only the file the
reviewer named: a wrong path is a citation error, not evidence of invention. Two
findings filed as Minor in one round were security bugs.

#### A refuted finding goes back to the agent that filed it

A finding that does not reproduce is **not closed** until the reviewer that filed it
has been shown the counter-evidence and has answered. One side declaring the other
wrong is how a real defect gets written off as a false positive — and if the refuter
is the one who is wrong, the bug ships and the loop records the round as clean.

Two Criticals about a trust boundary were once refuted silently, by one reader, in a
changelog entry. The reviewer had read the same file and concluded the opposite, and
nothing reconciled the two readings.

Send the refutation to **the same agent or profile that filed it** — it holds the
context that produced the claim, and the question is whether *that* reading survives
the counter-evidence. Give it the verbatim finding, the counter-evidence with
file:line and actual output, and a required answer shape:

```
VERDICT: withdrawn | stands | partially-stands
BECAUSE: <one paragraph, citing file:line or a command and its output>
```

Tell it to re-verify that finding only, to name precisely which step of the
counter-evidence is wrong if it stands, and not to open a findings file.

| Verdict | What to do |
|---|---|
| **withdrawn** | Record it as refuted *and confirmed refuted by the filer*. A closed disagreement, not a unilateral one. |
| **stands** | Drive the step it named. Assume the refutation was the error until the code says otherwise — a reviewer defending a finding after seeing contrary evidence is a stronger signal than the original filing. |
| **partially-stands** | Usually a real mechanism with an overstated impact. Fix the mechanism, correct the severity, and say both. |

#### A verdict's closing note is evidence, not a courtesy

The answer that comes back often carries more than the verdict — a caveat, an "also worth
checking", a branch the filer did not test. **Run those. They are pointers to an execution, not
footnotes.** The loop as described above closes the finding that was filed and has no step that
looks at anything else in the reply, so a note framed politely gets read, agreed with, and never
executed.

This is not hypothetical. One round's verdict ended with an unprompted line saying the fix covered
one scanner while two sibling branches had config paths of their own. The finding it was attached
to was already settled; the note was framed as "worth a line in the note if you want it complete".
Running it found a defect worse than the one under discussion — a branch that blocked *every*
commit, in code three careful readers and an entire static round had never executed.

The rule generalises the one in [phase 4 §13](phase-4-quality-gates.md): a check is not evidence
until you have seen it exercise the path. Applied there to a gate, applied here to a review — a
note naming an untested branch is the cheapest execution lead you will get, because someone who
just read that code is telling you where they did not look.

**This changes the loop's stopping condition.** A round is clean when no Critical
*survives verification*. A Critical the filer withdraws has not survived; one the
filer defends has, whatever the refuter believed.

#### Findings you do not action go to a backlog, not an archive

An archive nobody reads is the same as a delete. Head the file with **"every line
below is a claim, not a fact"** and mean it — across the three rounds one such list
came from, two of three Criticals were refuted on inspection and two Majors
described a real mechanism with an impact the code disproves.

Work it in scope order, not ID order: a scope's worth of rows shares context and the
verification cost drops sharply after the first two. Four exits per row, no fifth:

1. **Doesn't reproduce** — delete the row and say so in the commit.
2. **Reproduces** — fix it, add a regression test that fails against the pre-fix
   tree, delete the row.
3. **Reproduces but should not be fixed** — move it to the decision record with the
   reasoning ([phase 2b §5](phase-2b-recording-and-shipping.md)).
4. **Reproduces, and the fix moves content rather than changing it** — a conformance
   finding, an extraction, a relocation. Exit 2 is unreachable here: a
   behaviour-preserving move has no test that could fail on the pre-fix tree, and a
   finding forced down exit 2 gets closed with a test that proves nothing. Verify it
   with the round-trip check in [phase 3d §10](phase-3d-checking-what-you-claim.md) instead.

This list stood at three for a long time and said "no fourth". It was wrong: a
structural finding that survived both gates in [7a](phase-7a-running-a-review.md)
arrived at exit 2 and could satisfy it only by faking a test, so the honest routes
were to fake one or drop the finding. The fourth exit is the third option.

**Copy findings files somewhere durable before the release deletes them.** A round's
output is scratch on the way in and evidence on the way out. Seven rounds producing
~130 findings once left only the ~20 that were actioned, surviving in changelog
entries; the verified-and-declined, the refuted, and the not-yet-reached were lost.
The findings a round does not reach are the next round's starting point.
