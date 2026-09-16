# Rules card — operating

The second half of the rules card: working in a documented repo, delegating, reviewing,
and running unattended. Building rules — layout, config, design, resilience, verification,
quality gates — are in [rules-card.md](rules-card.md). Same contract as that file: one line
per rule, no rationale, open the named phase file for detail.

## Context docs — detail in [phase-5a-context-docs.md](phase-5a-context-docs.md)

- Under 15 files and 3 domains: no AGENTS.md. 15-50 files or 3-5 domains: root AGENTS.md. 50+ or 5+: hierarchy.
- Every AGENTS.md has purpose, ownership, local contracts, negative constraints, work guidance, verification.
- Create AGENTS.md immediately if you are duplicating code or unsure where a file belongs.
- The top-level doc holds what is expensive to relearn, not a description of the project.

## Maintaining context docs — detail in [phase-5c-maintaining-context-docs.md](phase-5c-maintaining-context-docs.md)

- Root context doc near 200 lines, domain doc near 300. Over budget: split or prune, don't compress.
- Run the task without the rule before adding it; if the agent already complies, don't add it.
- An incident buys a check, not a doc paragraph. Never paste a value a command could print.
- A rule scoped to a file pattern gets its own glob-scoped file, not a paragraph in the root doc.
- A `last-verified` date you will not refresh is worse than none.

## Working & delegating — detail in [phase-5b-working-and-delegating.md](phase-5b-working-and-delegating.md)

- Before editing, read the root AGENTS.md and every AGENTS.md on the path to each target. Don't rely on memory.
- The nearest doc wins on local detail; the parent wins on project-wide rules.
- After a meaningful change, update the nearest owning AGENTS.md and delete text that has gone stale.
- Output consumed by agents is plain text or markdown over JSON, minimal fields, deterministic order.
- Every subagent is defined by name, invocation, purpose, and an explicit negative constraint.

## Running a review — detail in [phase-7a-running-a-review.md](phase-7a-running-a-review.md)

- Read the context, security and handover docs in full before opening code. A finding contradicting one must name it.
- Self-refutation gate: an impact paragraph reaching "no practical impact" deletes the finding.
- Intent gate: engage with the comment or changelog explaining the behaviour before proposing a fix.

## The findings log — detail in [phase-7b-findings-log.md](phase-7b-findings-log.md)


## Verifying findings — detail in [phase-7c-verifying-findings.md](phase-7c-verifying-findings.md)

- Drive every finding against the code. Verify the claim, not the label; search the quoted snippet, not the cited path.
- Unactioned findings go to a backlog headed "every line is a claim". Four exits: delete, fix with a pre-fix-failing test, decide, or round-trip a move.

## What a round is worth — detail in [phase-7d-what-a-round-is-worth.md](phase-7d-what-a-round-is-worth.md)

- Reviewers at every depth find bad lines and miss missing ones. Answer a found class with a mechanical check.

## Unattended runs — detail in [phase-8a-unattended-runs.md](phase-8a-unattended-runs.md)

- Read the report, not the exit code. Every failure is a suspect, not a defect.
- Grants are named fields in the brief that default to refusing; every destructive step cites the one that allows it.
- Carry a budget proxy the agent can read — clock or cycles, not spend — and hand back at a cycle boundary when it crosses.
- List the one-way actions for this run; hitting one without a grant stops the run.
- A behavioural change to shipped code with no mechanical oracle is `verifier-only, unconfirmed` and does not close.
- Append verdicts and corrections as the run goes; a cold start reads that file and the tree.
- Stop on: a repeat failure after a documented repair, a fix needing a test changed, anything outside the test namespace, or a red tree.
## Instrumentation — detail in [phase-8b-instrumentation.md](phase-8b-instrumentation.md)

- Verify instrumentation before believing it; a measurement disagreeing with the system's own health check is the suspect.

## Reference

- Anti-patterns and deliberately excluded topics: [phase-6-reference.md](phase-6-reference.md)
- Sizing the ceremony to the project: [project-checklist.md](project-checklist.md)
- Driving a small or local model with this strategy: [small-model-operation.md](small-model-operation.md)
