# Phase 3g: Verifying against real targets

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-decision-records.md) · [2c](phase-2c-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) · [11](phase-11-debugging.md) — full names in [SKILL.md](../SKILL.md)

---

What the offline suite cannot tell you: whether a check works on the hosts, data and
environments it exists for. Writing the tests is [phase 3b](phase-3b-verifying.md); proving a
gate can go red at all is [phase 4](phase-4-quality-gates.md).

**Name each tier by what it proves, not by how long it takes.** A suite proving the
pipeline *runs* differs from one proving it *produces the right answers*; a project
owning only the first passes every test while a change halves output quality. Wire
the quality harness in as one pass/fail check against a recorded baseline, and keep
a table: command | what it proves | time | what it needs.

**A green suite that ran degraded is worse than a red one.** One project's missing
pair of environment variables made every vector call fail, so the tests silently
exercised the fallback paths and reported green for months while vector search never
ran. Add a **preflight test** that validates external dependencies and configuration
and fails fast with a readable message before any other test runs.

**Confirm the run mode you are actually in writes a log.** A preflight that validates
dependencies still passes when the mode you are running — one-shot, embedded,
subprocess — is the one that disables logging or metrics. Assert the observability
you intend to read is on, in that mode, before trusting a quiet run.

**The live tier finds what the offline suite cannot, so feed it back.** In one host-auditing
project, a session's best findings all came from real hosts: privileged checks passing
silently when the audit ran unprivileged, and a hardware probe that never produced a value on
any host. Every offline test had been green for both. Treat each live finding as a missing
offline case — add the case, see it fail, then fix.

**Record live, replay offline.** Capture a real target's output once, anonymise it, commit it
as a fixture, and pin the verdicts the checks must produce from it. The suite keeps offline
speed but runs on input the world produced rather than input you imagined. Key each recording
to the command that produced it, so changing the command fails the replay and forces a fresh
recording — otherwise the suite goes on testing a command nobody runs. A recording proves the
parsing and the verdict, not the probe: a changed probe still needs the live tier.

**A check that has never failed on a real target is unverified.** Breaking a gate once before
trusting it proves it *can* go red; it does not prove it fires on the thing it watches. Keep a
deliberately broken target — a host, container or fixture tree — whose defects are written
down, and assert its expected failures: each listed check fails there, for the listed reason.
A check that passes on the known-bad target is the bug, and a new check with no defect seeded
there is not done. The target costs upkeep; seed it for checks whose silent pass would be an
incident, not for every assertion.
