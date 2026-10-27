# 15 Running tests

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Running the suite and keeping its record: the living test plan, who reports and who fixes, a
red test as a possible defect, which flows have a test, and flakes. Writing the test is
[14](14-writing-tests.md); working a failure back to its cause is [20](20-debugging.md).

**Rules**

- The Results table records gate runs, audits and live verifications, never commits (15.1)
- A test runner reports; a test fixer fixes the code; never rewrite a test to make it pass (15.2)
- Treat a failing test as a possible defect first; prove an environmental cause on a correct environment (15.3)
- Index flows to tests; an uncovered flow is a row, not a silence (15.4)
- Characterise an in-process flake by looping it and recording the rate; ordering, parallel and machine-dependent ones need the failing configuration; rerun-and-green is not a fix (15.5)

### 15.1 A living test plan

`test-plan.md` in repo root.
- Numbered test cases with pass criteria
- Historical results table (date, environment, pass/fail per round)
- The Results table is not a change log: a row per gate run, audit or live verification,
  never per commit. What changed belongs to the changelog or git log, why to the decision
  log, or the commit message where there is none ([25.10](25-shipping.md)) -
  a fact written in several records drifts in all but one
- Bugs found during testing - recorded with fix commit reference
- Prerequisites section (services, env vars, configs)

**Operational testing guide:** `testing-guide.md` alongside test-plan.md. Covers how to run tests (commands), how to write new tests (code template), explicit rules for the chosen framework, and a pre-commit checklist. Separate from the living test plan (which tracks results) - this is the "how-to" reference.

### 15.2 A test runner reports; a test fixer fixes

- **Test runner agent** - runs tests, returns report (pass/fail with errors). Does NOT fix code.
- **Test fixer agent** - runs tests, analyzes errors, fixes root cause in code, re-runs, confirms passing.

Separation prevents the runner from silently "fixing" tests to pass instead of reporting genuine
failures. Runner is for CI/status checks; fixer is for debugging sessions - and *how* to work a
failure, rather than who works it, is [20](20-debugging.md). You will usually be in this
file when a test goes red, which is why the pointer is here rather than only in the routing table.

### 15.3 Treat a failing test as a possible defect first

One project documented six
failures as "environmental, do not fix by changing code." Five were a genuine bug.
Confirm an environmental cause by reproducing against a *correct* environment.

### 15.4 Index flows to tests, not only tests to assertions

The living test plan lists
what exists, so a flow with no test anywhere is silence, and silence about the login
path reads exactly like a login path that is fine. Keep a table of the flows whose
failure would be an incident - flow, entry point, covering test - where an uncovered
flow is a *row saying so*. Make the missing test a failing check only where you accept a red
suite until it is written; a ratchet ([14.6](14-writing-tests.md)) usually fits better.
Where a project can only afford one map, fold the column into the test plan rather
than starting a second document ([5.7](05-context-docs.md) on why two
maps of one territory drift).

### 15.5 Characterise a flake before dismissing it

Rerun-and-green is indistinguishable
from a fix and leaves no record the flake was ever seen. Loop the test, record how
many runs it took to fail, and treat that rate as the bug's severity. A loop only
reproduces flakes whose cause is in-process - ordering, parallelism and
machine-dependent ones need the failing configuration rather than repetition - so a
green loop is evidence about this shape of flake, not proof the flake is gone.
