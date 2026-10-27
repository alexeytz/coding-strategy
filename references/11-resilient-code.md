# 11 Resilient code

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

What keeps code standing once it meets real inputs and real outages. Proving it works is
[14](14-writing-tests.md); explaining it is [21](21-documenting.md); keeping credentials out of the history
that carries it is [22](22-secret-scanning.md); what crosses a trust boundary -
into a model, out of one, onto a deleted path - is [12](12-trust-boundaries.md).

The first six are non-negotiable; 11.7 and 11.8 only look optional until the first
incident; 11.9 is experimental; 11.10 is the one an atomic save gets wrong.

**Rules**

- Circuit-break external dependencies; an inner `try` that swallows a failure leaves the breaker inert (11.1)
- Guard every external return value for null before using it (11.2)
- An optional dependency that fails is logged and skipped; if the feature was wanted, the message names the command that fixes it (11.3)
- Migrations are idempotent and safe to re-run (11.4)
- One logger, one configuration; one `try` over two subsystems misnames the second, so split it or re-raise with the right name (11.5)
- Queries are parameterized; column names come from a hardcoded allowlist (11.6)
- Destructive actions default to dry-run on every surface - `config/safe-delete.sh` is one - and a deliberate divergence is documented where it diverges (11.7)
- A side-effecting call that times out is an unknown outcome: record intent first; retries reuse one intent-derived key claimed by a unique constraint (11.8)
- An atomic save copies the original file's mode onto the temp file before the rename; `mkstemp` creates it 0600; the save's test asserts the mode (11.10)
- A batch reports each item's outcome; one bad item never aborts or silently drops the good ones (11.11)

### 11.1 Circuit breakers for external deps

N consecutive failures → open circuit for cooldown → fallback. Reset on next success. A breaker counts what the *aggregate* saw, so any `try` nested inside the guarded operation must report the failure upward - an inner handler that swallows it leaves the breaker permanently inert, and a breaker that can never trip is decoration you trust.

### 11.2 Null/None guards everywhere

Every external call can return null. Guard before using, store placeholder, retry later.

### 11.3 Graceful degradation

When an optional dependency fails, the system continues without it (logged, not crashed). When the feature *was* wanted, the message names the command that fixes it, not just the condition: "install with `pip install yourpkg[pdf]`" beats "PDF support unavailable". Remediation text rots, so the named command needs a check that it still resolves - a message naming an install extra that was renamed is worse than a generic one.

### 11.4 Idempotent migrations

Schema changes wrapped in try/except. Safe to re-run. Never assume a column exists because you added it last week.

### 11.5 Shared logging

One logger, one configuration. File + console. Level from env var. One `try` spanning two subsystems can only name the first, so it misreports every failure of the second - and a wrong name in an error costs more than no name. Split the block, or catch and re-raise with the right one.

### 11.6 Parameterized queries

Always. Column names from hardcoded allowlists only. Never interpolate user input into SQL.

### 11.7 Destructive actions default to dry-run

Compact, merge, purge, resolve -
nothing changes without an explicit `execute=true`, on *every* surface that
exposes the action. In one project a test prompt that asked an agent to "report
the executed value" got it to pass `execute=true`, and a compaction merged six
real records. Keep the default inert and keep prompts that mention these actions
explicit that they must not execute.

Read this as a default rather than an absolute. A surface may diverge deliberately -
an internal batch path that must execute without a flag, a migration runner whose whole
job is to act - and the rule as written would make that a bug. **Document the divergence
at the divergence**, in the code that diverges, or the next reviewer files it as a finding
and the next agent "fixes" it back. That is the intent gate from
[33.5](33-running-a-review.md) turned around: the same obligation, owed by
the person writing the exception rather than the one reading it.

### 11.8 A timeout is a third outcome: unknown

A side-effecting call - a payment, a send, a
write to another system - can succeed, fail, or end without saying which. Treat unknown
as possibly done: record the intent before the call, and make the retry safe with a key
derived from the intent, never from the attempt, so every retry carries the same one.
Claim the key with a unique constraint, not check-then-insert, which two concurrent
retries both pass. Prior art: addyosmani/agent-skills' API design skill.

### 11.9 Experimental: agent-driven resilience

The two patterns below are **not** in the non-negotiable set. They are useful on long-running
agent workflows and carry failure modes the six above do not. Adopt deliberately, with the
guardrails, and only where a human reviews the result.

**Self-healing SDLC loop** - connect production/error logs to your agent so it periodically
reads logs and proposes fixes. The goal: bugs are detected and a proposed fix exists before a
human notices. The agent *proposes*; a human merges. An agent that both diagnoses and ships
its own fixes to production has no independent check on a wrong diagnosis.

**Self-modifying instructions** - a posture the operator enables and reviews, never one to take
up mid-task. Keep `AGENTS.md` and operational scripts in the working directory so the agent can
amend them when it hits a bug. Traditional software stops
when its instructions are wrong; an agent can route around its own broken instructions and
keep going, so a bad script makes it slower rather than blocked.

The cost is drift: instructions that quietly rewrite themselves stop being a contract, which is
the thing the rest of this document exists to protect. Required guardrails:

- **Append-only change log** - every self-modification recorded (timestamp, file, what changed,
  why) in a file the agent may append to but never rewrite.
- **Review before reuse** - a self-modified instruction is provisional. It gets human sign-off
  before a later session treats it as the contract.
- **Never self-modify** security boundaries, auth logic, secret handling, or the pre-commit
  hooks in [22](22-secret-scanning.md). A broken guardrail is not a bug to route around.
- **Scope it** - self-modification applies to operational scripts and working notes, not to the
  project's rules of record.

**When to use:** complex multi-step workflows where the agent iterates over many attempts and a
human reviews the accumulated changes at a known checkpoint. Not for unattended production.

### 11.10 Replacing a file keeps its mode

An atomic save, a temp file renamed over the original, does not edit the file: it replaces it,
and the new file has the temp file's permissions. Python's `tempfile.mkstemp` creates 0600, so a
shared data file quietly becomes readable by its owner alone, and nothing fails until another
user or service reads it. Copy the original's mode onto the temp file before the rename
(`shutil.copymode(path, tmp)`, when the original exists), and assert the mode in the test of the
save. In this skill's evals the change shipped in 9 of 24 hand-offs without a verifier ([28.6](28-delegating.md)) and 6 of 16
single-agent runs, with every test passing.

### 11.11 A batch fails item by item

One malformed id made a vector store refuse a whole batch delete; an element the database
could not bind aborted the valid deletes beside it; one record the embedder refused abandoned
all 64 in a rebuild that still reported success. Validate items before the call, report each
item's outcome, and continue past one that fails.
