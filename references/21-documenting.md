# 21 Documenting

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

How you explain the code to the next reader - the docstring, the README, the changelog.
Showing that it works is [14](14-writing-tests.md).

Principles for code-level documentation. Syntax (triple quotes, `///`, `/**`) belongs in language-specific skills - these are the rules that apply everywhere.

**Rules**

- Document behaviour, not implementation (21.1)
- Don't document obvious code, implementation detail or change history; a TODO in production code is fixed or tracked, not left (21.3)
- README answers: what, why, how to run, how to extend, known limits (21.6)
- Say which changelog is release notes and which is the decision record (21.7)

### 21.1 Document behavior, not implementation

Good docstring: "Returns the next 10 items sorted by timestamp. Raises `NotFoundError` if the collection is empty."

Bad docstring: "Iterates through the list, calls `sorted()` on timestamps, slices the first 10, then returns the result."

The reader can see the implementation by reading the code. The docstring answers "what does this do?" not "how does it do it?"

### 21.2 What to document

- **Public interfaces** - functions/methods visible outside the module. Parameters, return types, exceptions, side effects.
- **Edge cases** - what happens with empty input, null, duplicates, boundary values.
- **Invariants and preconditions** - "caller must hold lock X", "list must be sorted before calling".
- **Non-obvious choices** - why algorithm A instead of B, why this data structure, known trade-offs.
- **Configuration options** - what each setting does, valid ranges, defaults, and what breaks if wrong.

### 21.3 What not to document

- **Obvious code** - `x += 1` does not need a comment explaining it increments x.
- **Implementation details** - the code IS the implementation. If the docstring restates the code, delete the docstring.
- **History** - "changed on 2024-03-15 to fix bug #42" belongs in git log, not comments.
- **TODOs in production code** - either fix it or track it where the project tracks work: an issue, or `ta/` once the project has one ([9](09-task-assignments.md)). Comments age poorly.

### 21.4 When a comment is a smell

If you feel compelled to comment a block of code, ask: could this be a named function instead? A well-named function is better documentation than a comment above 10 lines of code.

### 21.5 Docstrings for agents

Agents consume documentation differently than humans. They don't skim - they read every token. Keep docstrings dense and specific:

- State parameter types and constraints explicitly ("`limit` - integer, 1-100, default 10")
- List exceptions with conditions ("raises `ValueError` if `limit` < 1")
- Include one concrete example for complex functions
- Avoid prose filler ("This function is used to..." → just describe the function)

### 21.6 README conventions

Every project ships a `README.md` that answers:
1. **What is this?** - one paragraph, no jargon
2. **Why does it exist?** - what problem it solves
3. **How to run it** - single command, working examples
4. **How to extend it** - architecture overview, key entry points
5. **Known limitations** - what it doesn't do, and why

### 21.7 Two documents share the name "changelog"

One is release notes for users - grouped
Added/Changed/Fixed, written for someone who did not read the diff. The other is a decision
record for whoever maintains the code: why a finding was refuted, why the code is shaped
this way, what a review already considered and rejected. [33.5](33-running-a-review.md)
sends a reviewer to the second one, and the rules below describe the first. Say in your repo
which file is which, and if you keep only one, say which job wins - applied literally to the
second, "skip internal refactors, write for the user" deletes the artifact a review depends on.

### 21.8 Changelog conventions

Track user-facing changes in `CHANGELOG.md` or the README:
- Group by: Added, Changed, Deprecated, Fixed, Removed
- Include date or version number
- Write for the user, not the developer ("API now returns pagination headers" not "added `Link` header support to response builder")
- Skip internal refactors - if the user can't observe the change, it doesn't go in the changelog
