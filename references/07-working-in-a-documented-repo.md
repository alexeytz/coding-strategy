# 7 Working in a documented repo

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

The operating discipline once an AGENTS.md hierarchy exists. Creating that hierarchy is
[5](05-context-docs.md); handing work to subagents is [28](28-delegating.md).

**Rules**

- Before editing, read the root AGENTS.md and every AGENTS.md on the path to each target; don't rely on memory (7.1)
- The nearest doc wins on local detail; the parent wins on project-wide rules (7.1)
- After every change, do a doc pass, even when a small edit ends with no doc changed; update the nearest owning AGENTS.md when contracts, structure or workflows moved, and remove what went stale (7.2, 7.5)
- A negative constraint you would revert a commit over gets a check that asserts it (7.4)
- A doc problem noticed in passing is fixed now if cheap and open, else one line in the existing backlog - or the commit message where there is none; never a second file beside it (7.6)
- Agent-only tool output is plain text or markdown over JSON - JSON when a machine parses it too; minimal fields, deterministic order (7.7)

### 7.1 Read before editing

1. Read the root `AGENTS.md`
2. Identify every file or folder you expect to touch
3. Walk from the repo root to each target path
4. Read every `AGENTS.md` found along each route
5. Use the nearest `AGENTS.md` as the local contract; parent docs for project-wide rules
6. If docs conflict, the closer doc controls local details - but no child doc may weaken a parent rule

If the domain you are editing has an `areas/<domain>-structure.md`, it is part of that chain -
read it with the AGENTS.md files and update it in the same doc pass. Without that, it is the one
doc in the chain that nothing keeps true.

Do not rely on memory. Re-read the applicable doc chain before editing.

### 7.2 Update after editing

Every meaningful change requires a doc pass before the task is done. Small edits that don't
change behavior or contracts may leave docs unchanged, but the doc pass still must happen.

**Update the nearest owning `AGENTS.md` when a change affects:**
- Purpose, scope, ownership, or responsibilities
- Durable structure, contracts, workflows, or operating rules
- Required inputs, outputs, permissions, constraints, or artifacts

### 7.3 Add a Negative Constraints section to every AGENTS.md

Good agent context needs three things: what to do, how to verify, and what NOT to do. Explicitly document known failure modes:

```markdown
## Negative Constraints
- What this agent should NOT do (known failure modes, past mistakes)
- Periodic maintenance: garbage collection, refactoring, dedup
- Output self-review: check its own work, verify edge cases
```

Example: "When a file exceeds ~2000 lines, evaluate: is it doing too many things? If yes, split. If no, document why it's monolithic and move on. Do periodic garbage collection. After generating UI code, verify mobile layout."

### 7.4 A negative constraint you would revert a commit over gets a guard, not just a sentence

The Negative Constraints section is the one most likely to be read and least likely to bind. One
agent, commissioned to audit a repo for gaps, created the exact file that repo's
Negative Constraints forbade by name - it had read the document, the prohibition was
stated in three places across two files, and its own report's "what I got wrong"
section said nothing needed correcting. The suite did not notice either, and the
reason generalises: a check suite naturally asserts that the files it knows about are
well-formed, and nothing asserts that a named file is *absent*. Pick the two or three
constraints that actually matter and assert the absence. It is three lines, and it
converts a request into a mechanism.

### 7.5 Parent and child docs

**Update parent docs when:** parent-level structure, ownership, workflow, or child index changes.
**Update child docs when:** parent changes alter local rules.
**Remove stale or contradictory text immediately.**

### 7.6 A doc problem you notice while doing something else leaves your head before your context does

A person who spots a stale path can act on it tomorrow; an agent's noticing does not
survive compaction or the end of a session, so deferring it is discarding it. Fix it in the
current commit when it is cheap and in a file you have open. Otherwise file one line in the
backlog the project already keeps ([35.5](35-verifying-findings.md)) - or, at a
tier with no backlog, in the commit message of the work in hand, which is the record those tiers
keep. Needing that repeatedly is [the checklist's](01-sizing-to-the-project.md) own trigger to create
one. **Never a second file:** a `doc-issues.md` beside a findings backlog is the second map
[5.7](05-context-docs.md) exists to prevent. And filing is not licence to chase -
recording an out-of-scope observation and moving on is what [34.5](34-findings-log.md)
already prescribes.

### 7.7 Agent-facing tool output

The same discipline applied outward: when the thing you are building in this repo is
itself consumed by an agent, its output is that agent's context budget.

Tools, MCP servers, and CLI utilities that agents will consume should output token-efficient data, not human-optimized JSON.

**Principles:**
- **Prefer plain text over JSON for agent-only output** - models parse JSON fine; the cost is
  tokens, not comprehension. JSON wrappers repeat every key on every record, so for a list of
  50 rows a markdown table or CSV can cost a fraction of the equivalent JSON. This is a cost
  argument, not a capability one - when a machine consumes the output too, JSON is correct.
- **Minimal default output** - When asked for data, return the relevant fields, not every column in the table. The agent can ask for more if needed.
- **Structured when necessary** - JSON is fine when a second system needs to parse the output programmatically. For agent-only consumption, prefer plain text, markdown tables, or CSV.
- **Consistent field ordering** - If you must output structured data, keep the field order deterministic across runs. Agents rely on positional patterns.

**Rule:** If you're building a tool that agents will use, benchmark the output size. A tool that returns 500 tokens instead of 3000 saves ~83% on every call.
