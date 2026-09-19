# Phase 7b: The findings log

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Where a review's output goes, and in what shape. Running the review is
[7a](phase-7a-running-a-review.md); acting on the output is
[7c](phase-7c-verifying-findings.md).

### 20. The findings log

**Write to a file of your own, at a known absolute path** — the repository root, not
`docs/`, not wherever your shell happens to be. A complete, well-evidenced log
written to the wrong directory reads as a run that produced nothing.

Name it `code_review_findings_<STAMP>_<MODEL>_<EFFORT>_<scope>.md`, with
`STAMP=$(date -u +%Y%m%dT%H%M%SZ)`. Model and effort level belong in the filename
because the same scope is deliberately re-run under different models and levels to
compare them, so one directory holds several logs of the same scope and must be
readable without opening any: stamp says when, model says who, tag says what. A
session cannot read its own model id or effort flag — **the launch line must state
them**. Write `unknown-model` rather than guessing; a wrong attribution is worse
than an absent one when the logs exist to compare models.

**Write the header before the first finding:** scope tag, stamp, model, effort,
protocol file, scope file, date, version, and tree `clean|dirty` from
`git status --short`. Fill every field — write `unknown` rather than leaving one
blank, because a blank reads as an oversight and `unknown` reads as a fact about the
run. A review of a dirty tree is still useful, but its findings must not be assumed
to map to the tagged release.

Per finding:

```
### F<n> [severity] <one-line claim>
- File:      <path>:<line>
- Code:      <the lines, quoted>
- Verified:  <what you read or ran that establishes this>
- Impact:    <what breaks, for whom, under what conditions — and say which half you
              drove and which you inferred; impact is the half that sets severity>
- Class:     <other sites sharing this pattern in scope, or "single site — searched
              for <pattern>, found none">
- Intent:    <the comment/doc explaining current behaviour, or "none found">
- Fix:       <the change, and why it does not contradict Intent>
```

**Append each finding the moment you confirm it — not at the end.** This is the rule
most often ignored, so it is worth being blunt. One run spent twenty minutes reading
every source file, planned to compile everything afterwards, and was cut off by an
unrelated timeout with the log still empty. It has since failed four more times: a
run that died holding its only finding in reasoning, one that enumerated forty
candidates and marked several real but wrote nothing, one that reported in chat
instead of the file. Each was recoverable only by reading transcripts, and only
because someone thought to look.

**Treat an empty findings file fifteen minutes into a run as a defect in your own
run, not as a sign you have found nothing.** A finding that is not in the file does
not exist.

#### Severity, assigned last

Assign severity only after the finding is verified, and by consequence, not by how
alarming it reads:

| Severity | Means |
|---|---|
| **Critical** | Silent data loss, a trust-boundary bypass, or a wrong answer the caller cannot detect |
| **Major** | A feature that does not do what it says, or a loud failure that blocks a documented path |
| **Minor** | Inefficiency, inconsistency, or a maintainability hazard with no behavioural effect |

Formatting, naming and indentation are Minor. A security bypass is Critical however
small the diff.

#### The final report

State the counts plainly — findings logged, verified, dropped at the self-refutation
gate — then three sections that are usually the most useful part of the whole run:

- **What I could not verify** — and what would settle each.
- **What I did not examine** — files or paths inside your scope you did not reach,
  so the reader knows the shape of the gap instead of assuming coverage.
- **What looked suspicious outside this scope** — named file and function, noticed
  and deliberately not chased.

**A run that reported nothing looks exactly like a run that found nothing.** Both
exit 0 and both leave a file. Check the final-report section exists before reading
the findings: in one round two of four bundles wrote nothing but their header after
27 and 10 minutes of wall clock, the driver logged success, and the round was
written up as fully dispositioned across four bundles when half of them had said
nothing. If you run reviews more than twice, automate that check.
