# Phase 3a: Writing resilient code

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [3e](phase-3e-pre-commit-security.md) · [3f](phase-3f-numbers-you-can-publish.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

What keeps code standing once it meets real inputs and real outages. Proving it works and
explaining it is [phase 3b](phase-3b-verifying.md); keeping credentials out of the history
that carries it is [phase 3e](phase-3e-pre-commit-security.md).

### 7. Error Resilience

Six non-negotiable patterns:

1. **Circuit breakers for external deps** — N consecutive failures → open circuit for cooldown → fallback. Reset on next success. A breaker counts what the *aggregate* saw, so any `try` nested inside the guarded operation must report the failure upward — an inner handler that swallows it leaves the breaker permanently inert, and a breaker that can never trip is decoration you trust.
2. **Null/None guards everywhere** — every external call can return null. Guard before using, store placeholder, retry later.
3. **Graceful degradation** — when an optional dependency fails, the system continues without it (logged, not crashed). When the feature *was* wanted, the message names the command that fixes it, not just the condition: "install with `pip install yourpkg[pdf]`" beats "PDF support unavailable". Remediation text rots, so the named command needs a check that it still resolves — a message naming an install extra that was renamed is worse than a generic one.
4. **Idempotent migrations** — schema changes wrapped in try/except. Safe to re-run. Never assume a column exists because you added it last week.
5. **Shared logging** — one logger, one configuration. File + console. Level from env var. One `try` spanning two subsystems can only name the first, so it misreports every failure of the second — and a wrong name in an error costs more than no name. Split the block, or catch and re-raise with the right one.
6. **Parameterized queries** — always. Column names from hardcoded allowlists only. Never interpolate user input into SQL.

Two more that only look optional until the first incident:

7. **Destructive actions default to dry-run.** Compact, merge, purge, resolve —
   nothing changes without an explicit `execute=true`, on *every* surface that
   exposes the action. In one project a test prompt that asked an agent to "report
   the executed value" got it to pass `execute=true`, and a compaction merged six
   real records. Keep the default inert and keep prompts that mention these actions
   explicit that they must not execute.
Read rule 7 as a default rather than an absolute. A surface may diverge deliberately —
an internal batch path that must execute without a flag, a migration runner whose whole
job is to act — and the rule as written would make that a bug. **Document the divergence
at the divergence**, in the code that diverges, or the next reviewer files it as a finding
and the next agent "fixes" it back. That is the intent gate from
[phase 7a §19](phase-7a-running-a-review.md) turned around: the same obligation, owed by
the person writing the exception rather than the one reading it.

8. **Fence stored content that is replayed to a model.** Anything your system did
   not author — web pages, imports, user uploads, a vault — is wrapped in a delimiter
   on the way out, with the delimiter stripped from the payload first. Three rules
   this gets wrong every time:
   - **Provenance, not columns.** A missing or empty source means *unknown*, which
     is untrusted. Treating absent-as-trusted opened the same hole three times in one
     project. Fencing also is not limited to the obvious text field — keyword lists,
     link lists and free-form metadata dicts need it too, and a free-form dict is
     serialized then fenced, because its injected keys are missed leaf-by-leaf.
   - **A trust label must never be settable by the caller.** Every external write
     path rewrites a caller-supplied source that claims a self-authored value. The
     corollary is that genuinely internal writers must bypass that boundary rather
     than have their legitimate source rewritten.
   - **Thread the label through the whole chain.** If the source does not reach the
     function that builds the prompt, the fence silently no-ops — no error, no log
     line. That is the failure mode to write a test for.

---

#### Experimental: agent-driven resilience

The two patterns below are **not** in the non-negotiable set. They are useful on long-running
agent workflows and carry failure modes the six above do not. Adopt deliberately, with the
guardrails, and only where a human reviews the result.

**Self-healing SDLC loop** — connect production/error logs to your agent so it periodically
reads logs and proposes fixes. The goal: bugs are detected and a proposed fix exists before a
human notices. The agent *proposes*; a human merges. An agent that both diagnoses and ships
its own fixes to production has no independent check on a wrong diagnosis.

**Self-modifying instructions** — keep `AGENTS.md` and operational scripts (bash, Python) in the
working directory so the agent can amend them when it hits a bug. Traditional software stops
when its instructions are wrong; an agent can route around its own broken instructions and
keep going, so a bad script makes it slower rather than blocked.

The cost is drift: instructions that quietly rewrite themselves stop being a contract, which is
the thing the rest of this document exists to protect. Required guardrails:

- **Append-only change log** — every self-modification recorded (timestamp, file, what changed,
  why) in a file the agent may append to but never rewrite.
- **Review before reuse** — a self-modified instruction is provisional. It gets human sign-off
  before a later session treats it as the contract.
- **Never self-modify** security boundaries, auth logic, secret handling, or the pre-commit
  hooks in §11. A broken guardrail is not a bug to route around.
- **Scope it** — self-modification applies to operational scripts and working notes, not to the
  project's rules of record.

**When to use:** complex multi-step workflows where the agent iterates over many attempts and a
human reviews the accumulated changes at a known checkpoint. Not for unattended production.
