# Phase 3b: Verifying

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

How you show the code works. Explaining it to the next reader is
[phase 3c](phase-3c-documenting.md); making it resilient in the first place is
[phase 3a](phase-3a-writing-resilient-code.md).

### 9. Test Isolation + Living Test Plan

**Test isolation:**
- Tests run in isolation — temp DBs, temp dirs, mocked external deps
- No shared state between tests
- Unset environment variables that redirect to live resources
- One test file per feature area (e.g., `test-export-import-decay.py`, not `test_all.py`)

**Framework choice:**
- Custom runner > framework dogma when the framework fights your project structure
- Assert-based with print output is fine for small projects
- If your project structure works with pytest/jest/go test, use them — no anti-framework bias

**Living test plan:** `test-plan.md` in repo root.
- Numbered test cases with pass criteria
- Historical results table (date, environment, pass/fail per round)
- Bugs found during testing — recorded with fix commit reference
- Prerequisites section (services, env vars, configs)

**Operational testing guide:** `testing-guide.md` alongside test-plan.md. Covers how to run tests (commands), how to write new tests (code template), explicit rules for the chosen framework, and a pre-commit checklist. Separate from the living test plan (which tracks results) — this is the "how-to" reference.

**Agent-level test separation:**
- **Test runner agent** — runs tests, returns report (pass/fail with errors). Does NOT fix code.
- **Test fixer agent** — runs tests, analyzes errors, fixes root cause in code, re-runs, confirms passing.

Separation prevents the runner from silently "fixing" tests to pass instead of reporting genuine failures. Runner is for CI/status checks; fixer is for debugging sessions.

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

**Treat a failing test as a possible defect first.** One project documented six
failures as "environmental, do not fix by changing code." Five were a genuine bug.
Confirm an environmental cause by reproducing against a *correct* environment.

**A result that depends on anything outside the repo is not a result.** Three
instances in three consecutive releases of one project: a path-existence test that
passed for whoever had run the suite (which wrote one of those paths) and failed on
a fresh clone of the same commit; a test reading the operator's real database as its
truth; and the test written to fix that, which asserted the operator's home
directory was clean and turned a correct checkout red. Before adding an assertion,
ask which question it answers — **about the repo** (same answer everywhere: assert
it) or **about this machine** (print it). One verdict must not answer both.

**Prefer invariant tests to shape tests.** Assert properties the system must never
violate — a merge never lowers a sensitivity flag, a purge never deletes inside the
grace period — and write each so it would have failed on the tree before its fix
landed. Worth more than another `assert isinstance(result, dict)`.

**Every test names the future diff that would turn it red.** If the only answer is
"editing the test itself", delete it — a suite of two hundred mirror assertions is
fully compliant with "prefer invariants" and guards nothing. Three admissible kinds:
a bug regression verified failing on the pre-fix tree (for a concurrency bug, a
deterministic interleaving — a stress loop that cannot hit the bug even on the buggy
code has zero guard value), a derived property, and critical-path bookkeeping. The
tie-breaker when you are unsure: would some regression pass every remaining test if
this case were deleted? Two shapes look like tautologies and stay — a literal copied
from an outside spec, and a negative branch no other case reaches. Apply the question
on the way in freely; apply it to **deleting** existing tests only with the whole
suite in view, because a wrong deletion is unrecoverable in a way a redundant test is
not, and that judgement is a poor fit for a small model
([small-model-operation.md](small-model-operation.md)).

**A decision the tree does not yet satisfy needs a ratchet, not a paragraph.** When
you ban a pattern that forty call sites predate, the rule is right and the tree is
not. Pin the violation count, fail on any rise — and on any unbanked fall, so the
number tracks reality in both directions. Exemptions live in the checker with a
reason each, and a check asserts the exemption list still matches the tree. Below a
handful of violations, fix them now and assert zero instead: the ratchet earns its
keep only when the count will not be zero this week.

**Index flows to tests, not only tests to assertions.** The living test plan lists
what exists, so a flow with no test anywhere is silence, and silence about the login
path reads exactly like a login path that is fine. Keep a table of the flows whose
failure would be an incident — flow, entry point, covering test — where an uncovered
flow is a *row saying so* and a named test that does not exist is a failing check.
Where a project can only afford one map, fold the column into the test plan rather
than starting a second document ([phase 5a §13](phase-5a-context-docs.md) on why two
maps of one territory drift).

**Confirm the run mode you are actually in writes a log.** A preflight that validates
dependencies still passes when the mode you are running — one-shot, embedded,
subprocess — is the one that disables logging or metrics. Assert the observability
you intend to read is on, in that mode, before trusting a quiet run.

**Characterise a flake before dismissing it.** Rerun-and-green is indistinguishable
from a fix and leaves no record the flake was ever seen. Loop the test, record how
many runs it took to fail, and treat that rate as the bug's severity. A loop only
reproduces flakes whose cause is in-process — ordering, parallelism and
machine-dependent ones need the failing configuration rather than repetition — so a
green loop is evidence about this shape of flake, not proof the flake is gone.
