# Phase 3e: Pre-commit security

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Keeping a credential out of history in the first place, and what to do once one is in.
Everything after the hook is worse than the hook, which is the whole argument for it.
Making the code itself survive real inputs is [phase 3a](phase-3a-writing-resilient-code.md).

### 11. Pre-commit Security

Automated secret scanning as a strict pre-commit hook. Catch secrets before they're committed — don't wait for a milestone audit.

**Minimum:** Run `gitleaks`, `trufflehog`, or `detect-secrets` on `git commit`. Block the commit if secrets are found.

**Why:** The "Never commit secrets" rule (Phase 1) is meaningless without enforcement. A pre-commit hook is the closest thing to guaranteed compliance — it runs locally on every commit, not just at audit time.

**Pattern:** `.gitleaks.toml` or `.detect-secrets-baseline` shipped in the repo. The baseline tracks false positives; the hook blocks new secrets.

**Verify the hook with a probe the scanner actually detects.** Installing this
into a real repo on 2026-09-05, the first control used AWS's published
documentation key (`AKIAIOSFODNN7EXAMPLE`) — which gitleaks allowlists
upstream, precisely because it is famously not a secret. The scan came back
clean and the hook was briefly recorded as inert when it was working. Probe
with a live-looking credential shape (a `ghp_`-style token), confirm the commit
is *blocked*, then confirm a clean commit still *passes*. Both directions, or
you have tested nothing.

**A secret that reached a remote is burned — rotate it, do not tidy it.** The hook above
exists because everything after this point is worse. Once a commit has been pushed, `git`
history rewriting is not a remedy: clones already hold it, and a host keeps the dangling
commit reachable by direct reference for a while after a force-push. On a public host the
scrapers arrive in seconds. So the order is **rotate the credential first**, then clean the
history, then work out how it got past the hook — and the hook gets the new case before you
move on. A rewritten history with a live credential still in it is the same failure as an
inert scanner: it looks handled.

Two more that cost a cycle each: `gitleaks protect` is deprecated in 8.x in
favour of `gitleaks git --staged`, so a hook pinned to the old spelling can
fall through to its own "no scanner installed" branch on a new install; and
allowlist regexes compile under Go's RE2, which has **no lookaround** — a
`(?!` there panics the whole scan rather than failing that rule, leaving the
repo unprotected while the hook still appears installed.
