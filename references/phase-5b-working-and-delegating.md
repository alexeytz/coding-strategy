# Phase 5b: Working & delegating

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

### 14. Working in a documented repo

The operating discipline once an AGENTS.md hierarchy exists. Creating that hierarchy is
[phase 5a](phase-5a-context-docs.md).

#### Read before editing

1. Read the root `AGENTS.md`
2. Identify every file or folder you expect to touch
3. Walk from the repo root to each target path
4. Read every `AGENTS.md` found along each route
5. Use the nearest `AGENTS.md` as the local contract; parent docs for project-wide rules
6. If docs conflict, the closer doc controls local details — but no child doc may weaken a parent rule

If the domain you are editing has an `areas/<domain>-structure.md`, it is part of that chain —
read it with the AGENTS.md files and update it in the same doc pass. Without that, it is the one
mandated doc with nothing keeping it true.

Do not rely on memory. Re-read the applicable doc chain before editing.

#### Update after editing

Every meaningful change requires a doc pass before the task is done.

**Update the nearest owning `AGENTS.md` when a change affects:**
- Purpose, scope, ownership, or responsibilities
- Durable structure, contracts, workflows, or operating rules
- Required inputs, outputs, permissions, constraints, or artifacts

**Add a Negative Constraints section to every AGENTS.md.** Good agent context needs three things: what to do, how to verify, and what NOT to do. Explicitly document known failure modes:

```markdown
## Negative Constraints
- What this agent should NOT do (known failure modes, past mistakes)
- Periodic maintenance: garbage collection, refactoring, dedup
- Output self-review: check its own work, verify edge cases
```

Example: "When a file exceeds ~2000 lines, evaluate: is it doing too many things? If yes, split. If no, document why it's monolithic and move on. Do periodic garbage collection. After generating UI code, verify mobile layout."

**A negative constraint you would revert a commit over gets a guard, not just a
sentence.** This is the section most likely to be read and least likely to bind. One
agent, commissioned to audit a repo for gaps, created the exact file that repo's
Negative Constraints forbade by name — it had read the document, the prohibition was
stated in three places across two files, and its own report's "what I got wrong"
section said nothing needed correcting. The suite did not notice either, and the
reason generalises: a check suite naturally asserts that the files it knows about are
well-formed, and nothing asserts that a named file is *absent*. Pick the two or three
constraints that actually matter and assert the absence. It is three lines, and it
converts a request into a mechanism.

**Update parent docs when:** parent-level structure, ownership, workflow, or child index changes.
**Update child docs when:** parent changes alter local rules.
**Remove stale or contradictory text immediately.**

Small edits that don't change behavior or contracts may leave docs unchanged, but the doc pass still must happen.

#### Agent-facing tool output

The same discipline applied outward: when the thing you are building in this repo is
itself consumed by an agent, its output is that agent's context budget.

Tools, MCP servers, and CLI utilities that agents will consume should output token-efficient data, not human-optimized JSON.

**Principles:**
- **Prefer plain text over JSON for agent-only output** — models parse JSON fine; the cost is
  tokens, not comprehension. JSON wrappers repeat every key on every record, so for a list of
  50 rows a markdown table or CSV can cost a fraction of the equivalent JSON. This is a cost
  argument, not a capability one — when a machine consumes the output too, JSON is correct.
- **Minimal default output** — When asked for data, return the relevant fields, not every column in the table. The agent can ask for more if needed.
- **Structured when necessary** — JSON is fine when a second system needs to parse the output programmatically. For agent-only consumption, prefer plain text, markdown tables, or CSV.
- **Consistent field ordering** — If you must output structured data, keep the field order deterministic across runs. Agents rely on positional patterns.

**Rule:** If you're building a tool that agents will use, benchmark the output size. A tool that returns 500 tokens instead of 3000 saves ~83% on every call.

### 15. Subagent registry

When delegating work to subagents, define them explicitly — don't leave their scope to inference.

**Registry location:** a table in `docs/agents.md` or the root `AGENTS.md`.

**Each subagent entry:**
- **Name** — short, lowercase, hyphenated (e.g., `browser-checker`)
- **Invocation** — how to call it (e.g., `@browser-checker <message>`)
- **Purpose** — what it does, one sentence
- **Negative constraints** — what it explicitly does NOT do

**Default roles every project should consider:**

| Role | Purpose | Negative constraint |
|------|---------|---------------------|
| `docs-maintainer` | Update docs after code changes | Does NOT write new features — only syncs docs to match code |
| `test-runner` | Run tests, return pass/fail report | Does NOT fix code — only reports |
| `test-fixer` | Analyze failures, fix root cause, confirm passing | Does NOT rewrite tests to pass — fixes the actual bug |
| `browser-checker` | Visual verification in browser | Does NOT modify DOM or application state |

**Don't advertise a capability you intend to refuse.** A tool that registers and then
returns "not enabled" spends the caller's attention on every listing and teaches it to
distrust the list. Withhold by not declaring, and keep refusal for cases the caller could
reasonably have expected to work. Pair it with one startup line saying what was withheld and
why — silent absence is harder to debug than a refusal, and an operator who forgot a flag
should see the switch named rather than a tool that never existed.

**Why a registry:** without it, subagents get vague instructions, duplicate work, or silently do the wrong thing. The registry makes delegation explicit and auditable.

#### A second writer in one checkout

A doc rule does not stop two agents interleaving unrelated edits into one diff; the commit
convention describes that mess rather than preventing it. The useful trigger is not "always
branch" but **branch when you find work already in progress that is not yours** — read-only
investigation and small tasks are fine in the shared checkout. Where your VCS supports it,
give the second task its own worktree and branch and do all edits and validation there. This
earns its place only once two agents actually run at once; for a solo operator who is always
the only writer it is cost with no return.

#### Delegation is bounded by the operator

Which tool or subscription a task runs on, when a session resets, and how remaining quota is
budgeted are operator decisions — an agent cannot see another tool's usage. Those rules live in
`../operator-guide.md`. Within a session, keep to the registry: use the named subagents for
their stated purpose and respect their negative constraints.
