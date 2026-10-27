# 18 Verifying against real targets

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

What the offline suite cannot tell you: whether a check works on the hosts, data and
environments it exists for. Writing the tests is [14](14-writing-tests.md); proving a
gate can go red at all is [24.4](24-quality-gates.md).

**Rules**

- Name each test tier by what it proves (18.1)
- A preflight test validates deps and config and fails fast (18.2)
- Assert the logging you mean to read is on in the run mode you are actually in (18.3)
- Each live finding becomes an offline case: add it, see it fail, then fix (18.4)
- Record a real target's output once and replay it offline; a changed command forces a new recording (18.5)
- A check that never failed on a target carrying the defect it watches is unverified; keep a known-bad target for checks whose silent pass would be an incident (18.6)
- Verify a build in a copy, and follow your own published install, exactly as printed, on a clean machine before release (18.7)

### 18.1 Name each tier by what it proves, not by how long it takes

A suite proving the
pipeline *runs* differs from one proving it *produces the right answers*; a project
owning only the first passes every test while a change halves output quality. Wire
the quality harness in as one pass/fail check against a recorded baseline, and keep
a table: command | what it proves | time | what it needs.

### 18.2 A green suite that ran degraded is worse than a red one

One project's missing
pair of environment variables made every vector call fail, so the tests silently
exercised the fallback paths and reported green for months while vector search never
ran. Add a **preflight test** that validates external dependencies and configuration
and fails fast with a readable message before any other test runs.

### 18.3 Confirm the run mode you are actually in writes a log

A preflight that validates
dependencies still passes when the mode you are running - one-shot, embedded,
subprocess - is the one that disables logging or metrics. Assert the observability
you intend to read is on, in that mode, before trusting a quiet run.

### 18.4 The live tier finds what the offline suite cannot, so feed it back

In one host-auditing
project, a session's best findings all came from real hosts: privileged checks passing
silently when the audit ran unprivileged, and a hardware probe that never produced a value on
any host. Every offline test had been green for both. Treat each live finding as a missing
offline case - add the case, see it fail, then fix.

### 18.5 Record live, replay offline

Capture a real target's output once, anonymise it, commit it
as a fixture, and pin the verdicts the checks must produce from it. The suite keeps offline
speed but runs on input the world produced rather than input you imagined. Key each recording
to the command that produced it, so changing the command fails the replay and forces a fresh
recording - otherwise the suite goes on testing a command nobody runs. A recording proves the
parsing and the verdict, not the probe: a changed probe still needs the live tier.

### 18.6 A check that has never failed on a real target is unverified

Breaking a gate once before
trusting it proves it *can* go red; it does not prove it fires on the thing it watches. Keep a
deliberately broken target - a host, container or fixture tree - whose defects are written
down, and assert its expected failures: each listed check fails there, for the listed reason.
A check that passes on the known-bad target is the bug, and a new check with no defect seeded
there is not done. The target costs upkeep; seed it for checks whose silent pass would be an
incident, not for every assertion.

### 18.7 Follow your own install on a clean machine

[16.1](16-checking-what-you-claim.md) says to test the artifact. Do it in a copy: verifying in
place left compiled files and test results in a tree that was about to be published. And before
a release, follow the published install steps exactly as printed, on a machine that has never
had the project. In one project three such runs each found an install breaker no in-repo check
could see; one was a dependency check reporting READY under an interpreter that had none of the
dependencies.
