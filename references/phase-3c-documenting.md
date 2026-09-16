# Phase 3c: Documenting

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1a](phase-1a-layout.md) · [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

How you explain the code to the next reader — the docstring, the README, the changelog.
Showing that it works is [phase 3b](phase-3b-verifying.md).

### 10. Code Documentation

Principles for code-level documentation. Syntax (triple quotes, `///`, `/**`) belongs in language-specific skills — these are the rules that apply everywhere.

**Document behavior, not implementation.**

Good docstring: "Returns the next 10 items sorted by timestamp. Raises `NotFoundError` if the collection is empty."

Bad docstring: "Iterates through the list, calls `sorted()` on timestamps, slices the first 10, then returns the result."

The reader can see the implementation by reading the code. The docstring answers "what does this do?" not "how does it do it?"

**What to document (always):**
- **Public interfaces** — functions/methods visible outside the module. Parameters, return types, exceptions, side effects.
- **Edge cases** — what happens with empty input, null, duplicates, boundary values.
- **Invariants and preconditions** — "caller must hold lock X", "list must be sorted before calling".
- **Non-obvious choices** — why algorithm A instead of B, why this data structure, known trade-offs.
- **Configuration options** — what each setting does, valid ranges, defaults, and what breaks if wrong.

**What NOT to document:**
- **Obvious code** — `x += 1` does not need a comment explaining it increments x.
- **Implementation details** — the code IS the implementation. If the docstring restates the code, delete the docstring.
- **History** — "changed on 2024-03-15 to fix bug #42" belongs in git log, not comments.
- **TODOs in production code** — either fix it or track it in `ta/`. Comments age poorly.

**When is a comment a smell?**

If you feel compelled to comment a block of code, ask: could this be a named function instead? A well-named function is better documentation than a comment above 10 lines of code.

**Docstrings for agents vs humans**

Agents consume documentation differently than humans. They don't skim — they read every token. Keep docstrings dense and specific:

- State parameter types and constraints explicitly ("`limit` — integer, 1-100, default 10")
- List exceptions with conditions ("raises `ValueError` if `limit` < 1")
- Include one concrete example for complex functions
- Avoid prose filler ("This function is used to..." → just describe the function)

**README conventions**

Every project ships a `README.md` that answers:
1. **What is this?** — one paragraph, no jargon
2. **Why does it exist?** — what problem it solves
3. **How to run it** — single command, working examples
4. **How to extend it** — architecture overview, key entry points
5. **Known limitations** — what it doesn't do, and why

**Two documents share the name "changelog".** One is release notes for users — grouped
Added/Changed/Fixed, written for someone who did not read the diff. The other is a decision
record for whoever maintains the code: why a finding was refuted, why the code is shaped
this way, what a review already considered and rejected. [Phase 7a §16](phase-7a-running-a-review.md)
sends a reviewer to the second one, and the rules below describe the first. Say in your repo
which file is which, and if you keep only one, say which job wins — applied literally to the
second, "skip internal refactors, write for the user" deletes the artifact a review depends on.

**Changelog conventions**

Track user-facing changes in `CHANGELOG.md` or the README:
- Group by: Added, Changed, Deprecated, Fixed, Removed
- Include date or version number
- Write for the user, not the developer ("API now returns pagination headers" not "added `Link` header support to response builder")
- Skip internal refactors — if the user can't observe the change, it doesn't go in the changelog
