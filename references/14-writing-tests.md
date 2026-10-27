# 14 Writing tests

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

How you show the code works, at the moment you write the assertion. Running the suite and
keeping its record is [15](15-running-tests.md); explaining the code to the next reader is
[21](21-documenting.md); making it resilient in the first place is [11](11-resilient-code.md);
showing it works on the real hosts and data it is for is
[18](18-verifying-against-real-targets.md).

**Rules**

- Tests run isolated: temp dirs and DBs, mocked externals, no shared state, one file per feature area (14.1)
- Assert questions about the repo; print questions about this machine (14.2)
- Prefer invariant tests over shape tests, each written to fail on the tree before its fix (14.3)
- Every new test names the future diff that would turn it red; delete an existing one for failing that only with the whole suite in view (14.4)
- For new code, invert one condition and rerun, then restore the file from a copy; a mutation still green names a missing test; every guard also gets an input it must accept (14.5)
- A ban the tree violates more than a handful of times gets a ratchet: pin the count, fail on any rise and any unbanked fall; below that, fix and assert zero (14.6)

### 14.1 Test isolation

- Tests run in isolation - temp DBs, temp dirs, mocked external deps
- No shared state between tests
- Unset environment variables that redirect to live resources
- One test file per feature area (e.g., `test-export-import-decay.py`, not `test_all.py`)

**Framework choice:**
- Custom runner > framework dogma when the framework fights your project structure
- Assert-based with print output is fine for small projects
- If your project structure works with pytest/jest/go test, use them - no anti-framework bias

### 14.2 A result that depends on anything outside the repo is not a result

Three
instances in three consecutive releases of one project: a path-existence test that
passed for whoever had run the suite (which wrote one of those paths) and failed on
a fresh clone of the same commit; a test reading the operator's real database as its
truth; and the test written to fix that, which asserted the operator's home
directory was clean and turned a correct checkout red. Before adding an assertion,
ask which question it answers - **about the repo** (same answer everywhere: assert
it) or **about this machine** (print it). One verdict must not answer both.

### 14.3 Prefer invariant tests to shape tests

Assert properties the system must never
violate - a merge never lowers a sensitivity flag, a purge never deletes inside the
grace period - and write each so it would have failed on the tree before its fix
landed. Worth more than another `assert isinstance(result, dict)`.

### 14.4 Every test names the future diff that would turn it red

If the only answer is
"editing the test itself", delete it - a suite of two hundred mirror assertions is
fully compliant with "prefer invariants" and guards nothing. Three admissible kinds:
a bug regression verified failing on the pre-fix tree (for a concurrency bug, a
deterministic interleaving - a stress loop that cannot hit the bug even on the buggy
code has zero guard value), a derived property, and critical-path bookkeeping. The
tie-breaker when you are unsure: would some regression pass every remaining test if
this case were deleted? Two shapes look like tautologies and stay - a literal copied
from an outside spec, and a negative branch no other case reaches. Apply the question
on the way in freely; apply it to **deleting** existing tests only with the whole
suite in view, because a wrong deletion is unrecoverable in a way a redundant test is
not, and that judgement is a poor fit for a small model
([30.3](30-handing-work-to-a-small-model.md)).

### 14.5 For new code, run a mutation instead of reasoning

Invert one condition the
change adds - drop a negation, swap `<` for `<=`, `and` for `or` - run the suite, then
restore the file from the copy you made first. A mutation that stays green is a finding: name the case that
is missing and write it. One mutation per condition, by hand; this is a probe, not a
mutation-testing framework. Prior art: addyosmani/agent-skills' code-review skill.
The same blind spot in a fixture: where two readings of the code would give the same value on
it, it cannot tell them apart. A mock that made time-to-first-response equal
time-to-first-token passed a formula that used the wrong one. Give each candidate reading a
different value. And a mutation asks only whether a guard fires: give every guard a valid input
too, that it must accept. One guard passed every mutation and broke eight legitimate imports on
its first real run; another raised on every input, so it "refused" correctly and accepted
nothing. Confirm the mutation applied, by diffing the file, before reading "survived": a `sed`
that failed to compile left the file unchanged and the probe reported a missing test. The same
holds for any edit that must happen, such as a substitution at publish time: assert it matched.

### 14.6 A decision the tree does not yet satisfy needs a ratchet, not a paragraph

When
you ban a pattern that forty call sites predate, the rule is right and the tree is
not. Pin the violation count, fail on any rise - and on any unbanked fall, so the
number tracks reality in both directions. Exemptions live in the checker with a
reason each, and a check asserts the exemption list still matches the tree. Below a
handful of violations, fix them now and assert zero instead: the ratchet earns its
keep only when the count will not be zero this week.
