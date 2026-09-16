# Operator guide

Companion to the `coding-strategy` skill. **This file is for the human running the work, not
for the agent to load.** Everything here is a decision an agent cannot make for itself —
because it needs information the agent can't see (quota across subscriptions, what you
actually want built) or because it's the prompt you paste to start the agent off.

Agent-facing rules live in `references/phase-*.md`. Where a rule has both a human and an agent
half, the agent half stays in the phase file and is cross-referenced here.

---

## Bootstrap prompts

Prompts worth keeping verbatim. They're the entry points where the agent has no context yet.

### Building the AGENTS.md hierarchy

For an undocumented repo that meets the CREATE threshold
(see `references/phase-5a-context-docs.md`):

> Build the AGENTS.md hierarchy for this repo — scan all folders, create a child AGENTS.md in
> each domain folder with purpose, ownership, local contracts, and a child index.

The agent reads the codebase and creates the tree (~5 min for a medium repo). No install, no
tool — just markdown files. Review the result before trusting it: the agent will infer
ownership and conventions that only you can confirm.

### Pre-design interview

Before the agent writes a design doc
(see `references/phase-2a-designing-a-change.md`):

> Act as a technical interviewer. Ask me clarifying questions about what I'm trying to build.
> Don't proceed until you've explored edge cases, data requirements, and failure modes.
> Ask one question at a time.

Humans are bad at expressing requirements upfront. The agent only knows what it's told; it
won't surface forks in the road until you're forced to confront them. This catches ambiguity
before it becomes code.

---

## Orchestration across tools

When you're running multiple agents across different tools or subscriptions, these are your
calls to make. The orchestrating session — the one that dispatches work rather than doing it,
what these projects call the *First Mate* — owns them.

### Session reset pacing

Reset agent sessions at natural breakpoints: a milestone completed, the context window
approaching its limit, or the work switching domains. Not on an arbitrary clock. Every reset
costs the new session time re-establishing context, so a reset mid-task is pure loss.

### Quota awareness before dispatch

Check subscription and API usage *before* delegating. If a tool's quota is nearly exhausted,
route the task elsewhere or defer it until reset — a task started on a half-depleted budget
tends to die at the expensive end, with the work half-done and the context gone.

### Tool routing

Track usage across the tools available to you and rotate based on remaining quota, rather than
always reaching for the same one. An agent cannot do this for you: it has no visibility into
another tool's account.

---

## Decisions the agent must not make alone

Collected from across the phases, for when you're deciding how much rope to give a session:

- **Data schema** — the agent proposes, you approve. Agent-designed schemas produce features
  the data layer can't support (`references/phase-6-reference.md`).
- **Feature selectivity** — an agent will happily generate a hundred individually reasonable
  features that are collectively unmaintainable. Saying no is your job.
- **Escalate / Block tier findings** — anything touching public API shape, auth, security
  boundaries, or a migration with data-loss potential
  (`references/phase-4-quality-gates.md`).
- **Contradictory task assignments** — if a `ta/` file contradicts itself, the agent is
  instructed to ask rather than pick (`references/phase-2a-designing-a-change.md`).
- **Where the code is hosted.** Not a technical choice — a custody choice, and it needs
  information an agent does not have: your client contracts, your employer's policy, whether
  this repo will ever be public. Decide it once, per project, before the first commit, because
  moving a repo later does not move what has already been fetched.
  - A **public** repo is scraped continuously. A secret that lands in one is burned in seconds,
    not minutes, and rewriting history does not recall it.
  - A **private** repo on someone else's service is still their custody: their terms, their
    breach surface, their response to a subpoena. That is a policy guarantee, not a technical
    one, and policies change without asking you.
  - **Self-hosted** (a local `git`, a Gitea or Forgejo instance) removes the third party and
    adds the backup and availability problem that third party was solving. That trade is the
    decision; there is no option without one.

  Whatever you choose, configure the remote yourself and let the agent inherit it. The agent
  half of this rule — never add a remote, never push to a host it was not given — is in
  `references/phase-2b-recording-and-shipping.md` §6, because it is a rule an agent can follow
  and this is a judgement it cannot make.

- **Accumulated self-modifications** — if you enabled the experimental self-modifying
  instructions pattern, the change log needs a human read at a known checkpoint
  (`references/phase-3a-writing-resilient-code.md`).
