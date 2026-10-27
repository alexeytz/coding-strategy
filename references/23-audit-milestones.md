# 23 Audit milestones

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

What has to be true before work is declared done: the audit, and the tiers its findings are
sorted into. Gates that can actually fail are [24](24-quality-gates.md); writing the handover
is [27](27-handover.md).

**Rules**

- A milestone is done only after a dated audit - tests, security scan, dangerous patterns, performance, lint, bug count - with a GO/NO-GO verdict (23.1)
- Classify every automated-scan finding as auto-fix, queue-for-review, escalate or block; default to auto-fix; a code-review finding goes through 35 first (23.2)
- Escalate anything touching public API shape, auth, security boundaries or product behaviour; block on a migration that can lose data (23.2)

### 23.1 Audit-gated milestones

Formal report before declaring a milestone "done." Timestamped. GO/NO-GO verdict.

**Minimum sections:**
- Test results table (pass/fail per category)
- Security scan (language-appropriate tool: Bandit, Gosec, cargo-audit, eslint-plugin-security)
- Manual review of dangerous patterns (SQL injection, path traversal, SSRF)
- Performance profile with thresholds (operation | avg | p95 | threshold | status); thresholds from the design doc's estimate (8.2), or the measured baseline where none was set
- Code quality (linter output, violations count)
- Confirmed bugs count

**Keep audit reports in the repo** as `AUDIT-YYYY-MM-DD.md` or `PRODUCTION-READINESS-AUDIT-YYYY-MM-DD.md`.

### 23.2 Escalation tiers for findings

When running automated review (test-fixer agent, lint scanner, security checker), classify findings into tiers rather than escalating everything:

| Tier | Action | Example |
|------|--------|---------|
| **Auto-fix** | Agent fixes immediately, no human involvement | Trailing whitespace, unused import, typo in error message |
| **Queue for review** | Agent fixes and batches for human sign-off after all auto-fixes are done | Refactoring a function, changing variable names, updating a docstring |
| **Escalate** | Agent presents the finding + proposed fix, waits for human approval | Removing a feature flag, changing API response shape, modifying auth logic |
| **Block** | Agent stops, requires human decision before continuing | Incompatible dependency upgrade, data migration with potential data loss |

**Why tiers:** Without them, either the agent is overwhelmed with trivial decisions or the human is spammed with every minor fix. Tiers let the agent handle noise and only surface decisions that matter.

**Rule:** Default new findings to auto-fix. Escalate upward only when the change affects public APIs, security boundaries, or product behavior.
