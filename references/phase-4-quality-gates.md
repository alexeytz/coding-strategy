# Phase 4: Quality gates

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

### 11. Audit-Gated Milestones

Formal report before declaring a milestone "done." Timestamped. GO/NO-GO verdict.

**Minimum sections:**
- Test results table (pass/fail per category)
- Security scan (language-appropriate tool: Bandit, Gosec, cargo-audit, eslint-plugin-security)
- Manual review of dangerous patterns (SQL injection, path traversal, SSRF)
- Performance profile with thresholds (operation | avg | p95 | threshold | status)
- Code quality (linter output, violations count)
- Confirmed bugs count

**Keep audit reports in the repo** as `AUDIT-YYYY-MM-DD.md` or `PRODUCTION-READINESS-AUDIT-YYYY-MM-DD.md`.

#### Adversarial review escalation tiers

When running automated review (test-fixer agent, lint scanner, security checker), classify findings into tiers rather than escalating everything:

| Tier | Action | Example |
|------|--------|---------|
| **Auto-fix** | Agent fixes immediately, no human involvement | Trailing whitespace, unused import, typo in error message |
| **Queue for review** | Agent fixes and batches for human sign-off after all auto-fixes are done | Refactoring a function, changing variable names, updating a docstring |
| **Escalate** | Agent presents the finding + proposed fix, waits for human approval | Removing a feature flag, changing API response shape, modifying auth logic |
| **Block** | Agent stops, requires human decision before continuing | Incompatible dependency upgrade, data migration with potential data loss |

**Why tiers:** Without them, either the agent is overwhelmed with trivial decisions or the human is spammed with every minor fix. Tiers let the agent handle noise and only surface decisions that matter.

**Rule:** Default new findings to auto-fix. Escalate upward only when the change affects public APIs, security boundaries, or product behavior.

#### A hook is a speed bump; CI is the gate

Both matter and they are not the same thing. A pre-commit hook gives the fast local signal,
and it is bypassable — `--no-verify` exists, and the hook's own error message usually
mentions it. So anything that must not be bypassed runs in CI as well, and CI is where a
merge is actually blocked. A check earns its place in the hook by being fast and
deterministic; it earns its place in CI by mattering. The secret scan belongs in both, for
exactly this reason: locally it stops the commit, and in CI it stops the merge when someone
skipped the hook.

#### Adopting a linter into an existing codebase

Turning a full ruleset on at once against a tree that predates it produces thousands of
diagnostics and teaches everyone to ignore the linter. Turn the whole thing on **advisory**,
and report it as a delta against the merge base, keyed so unrelated line shifts do not read
as new findings. A rule graduates to **blocking** only when an incident bought it, and its
config comment names that incident. Keep the two in separate jobs so the blocking set is
never diluted by the advisory noise. This is [phase 3b §9](phase-3b-verifying.md)'s ratchet
pointed at a linter — and the same threshold decides between them: on a small or new
codebase, fixing everything and turning the linter fully blocking is cheaper than building
the two-job machinery. The delta gate is for the tree too large to fix this week.

#### Every gate declares what it does not cover

An audit checklist of greens with no negative space invites a conclusion it cannot
support. A gate ships a named section saying what it deliberately does not check and why —
and, for anything protective, what defeats it: "a PR can edit this workflow, so these
guards catch accidents and casual attempts, not a determined author; branch protection and
human review of workflow diffs remain the real backstop." The absence of that section is
the defect, not the absence of coverage. It is a documentation habit rather than a
mechanism, so it survives only where a doc-truth check asserts the section exists
([phase 3d §21](phase-3d-checking-what-you-claim.md)); without one it becomes the ritual
paragraph nobody updates when coverage changes.

#### A gate you have not seen fail is not a gate

Before trusting any checker, grader or detector, break the thing it watches and confirm it goes
red. Two ways this fails, and both ship green:

- **The wiring cannot fail.** One project's CI compiled a file and piped the compiler through
  `head`; a pipeline exits with the status of its *last* command, so the compiler's errors were
  masked and the job could only ever pass. It guarded the one file nothing else compiled. Never
  pipe the checked command into anything.
- **The judgement is wrong.** A correctness gate once reported a large regression that did not
  exist — it could not read unfenced code, and tested for a deliverable the prompt never asked
  for, between them accounting for 72 of 74 failures. The answer is structural: every grader
  carries a known-good reference that must pass *and* a plausible-wrong one that must fail, and
  refuses to run when it cannot tell them apart. Where judging is expensive, prove the logic
  offline for free and the judgement separately.

The same rule read backwards: a check that cannot run is not a gate either. A path-filtered
required check stays pending forever when no matching file changes, which blocks the merge it was
meant to guard.

### 12. Handover Protocol

Structured markdown document for session continuity.

**Required sections:**
- Load order (what to read first, in order)
- Current state (version, line counts, key features)
- Recent commits (last 5-10, with dates)
- Testing status (test counts, last run results)
- Remaining work (prioritized table)
- Known limitations (bullet list)
- Session chain reference (link to sessions.txt)

**Two sections worth more than the rest, and usually missing:**

- **Settled with measurements — do not re-open without new evidence.** Each entry:
  the question, the number that answered it, the date. This is what stops a later
  session (or a review) from proposing the change that caused the bug the code
  exists to prevent.
- **Traps, each one paid for.** The things that are expensive to relearn: the
  environment quirk, the flag that must be passed, the command that looks like it
  worked. Write the symptom first — that is what the next reader will be searching
  for — then the cause, then the fix.

**Ends with an instruction:** "Load these docs in order above, then ask the user: What do you need to do?"

**Location:** `handover.md` in repo root. Updated after every significant session.

**Correct it in place when it is wrong.** One project's handover carried a note
saying a set of test failures was environmental and must not be fixed in code; five
of the six were a real bug. The note stayed for weeks and cost real time. A handover
is a claim about the present, so an entry that turns out to be wrong is rewritten
with what was learned — not left standing beside its correction.

