# Phase 8b: Instrumentation

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Being able to believe what you measured. Every rule here cost a debugging session,
and most are this strategy's own rules applied to its tooling — which is exactly
where they get forgotten. Running the loop itself is [8a](phase-8a-unattended-runs.md).

### 23. Instrumentation you can believe

Every rule here cost a real debugging session, and most of them are the project's
own rules applied to its tooling — which is exactly where they get forgotten.

- **Verify the instrumentation before believing it.** A debug spy that consumed an
  error response body made a working repair look broken. A census script that opened
  the store under a slightly misspelled name reported zero records for a healthy
  system, and the "restore" that followed was the only thing that ever damaged it.
  **When a measurement disagrees with the system's own health check, suspect the
  measurement.**
- **Prove the instrument can fail before the run, not during it.** "Verify the
  instrumentation" is the rule; the mechanism is a known-good input that must pass
  and a plausible-wrong one that must fail, run as a precondition rather than as a
  flag — one project's judge refuses the whole matrix when it cannot rank the pair
  correctly. See [phase 4 §13](phase-4-quality-gates.md).
- **A count is not a membership test.** `ps -ef | grep -c` reported three leftover
  servers where there were none — the pipeline matched itself. Count by listing what
  you found and reading the list.
- **Process-matching predicates match themselves.** An
  `until ! pgrep -f "run-regression.py"; do sleep 15; done` waiter contains that
  string, matches its own command line and never exits; it polled for hours before
  anyone noticed, because it was blocked before its first line of output. Gate
  background waiters on their **output file** instead. In the same environment
  `kill`/`pkill` aborted the calling shell command, so run them alone and verify
  afterwards rather than chaining.
- **A silent background task is indistinguishable from an absent one.** A monitor
  whose patterns match only failures prints nothing on a healthy run and outlives
  what it was watching — one survived sixteen hours. Enumerate what you started, and
  at the end confirm each is stopped by *listing*, not by counting.
- **Bound log inspection to the session.** An incident report once named the wrong
  root cause because a bare `HH:MM` grep against a log that appends across sessions
  for weeks read every previous day at that clock time as one timeline. Scan between
  the session's own start markers, and build that boundary into the gate script
  rather than trusting each reader to remember.
