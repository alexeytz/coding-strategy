# Phase 1a: Layout

Part of the `coding-strategy` skill. Language-agnostic patterns extracted from real
projects (HLM plugin, Odysseus, ComfyUI, vibecode-setup-public). Not dogma — follow
unless there's a reason not to.

Other phases: [1b](phase-1b-config-and-setup.md) · [2a](phase-2a-designing-a-change.md) · [2b](phase-2b-recording-and-shipping.md) · [3a](phase-3a-writing-resilient-code.md) · [3b](phase-3b-verifying.md) · [3c](phase-3c-documenting.md) · [3d](phase-3d-checking-what-you-claim.md) · [4](phase-4-quality-gates.md) · [5a](phase-5a-context-docs.md) · [5b](phase-5b-working-and-delegating.md) · [5c](phase-5c-maintaining-context-docs.md) · [6](phase-6-reference.md) · [7a](phase-7a-running-a-review.md) · [7b](phase-7b-findings-log.md) · [7c](phase-7c-verifying-findings.md) · [7d](phase-7d-what-a-round-is-worth.md) · [8a](phase-8a-unattended-runs.md) · [8b](phase-8b-instrumentation.md) · [9](phase-9-releasing.md) · [10](phase-10-data-architecture.md) — full names in [SKILL.md](../SKILL.md)

---

Where code goes, and what keeps it findable. Configuration and setup scripts are
[1b](phase-1b-config-and-setup.md).

### 1. Interface / Engine / Features

Thin public API, fat internal engine, pluggable feature modules.

```
project/
  interface/       # Types, schemas, dispatch, routing — NOTHING else
  engine/          # Core logic, pipelines, CRUD, external integrations
  features/        # One module per capability (summaries, export, ingest, ...)
  config/          # Data files: patterns, thresholds, defaults
  tests/           # Test runners + living test plan
```

This invariant is also a working-set bound: it caps how much a reader — human or model — must
hold at once to change one thing. See [small-model-operation.md](small-model-operation.md).

**Invariant:** one feature touches at most 2 *source* files (interface schema + engine
method). Never 5 source files for one feature. Doc updates (AGENTS.md, handover, design
doc) are not counted — they are expected on top. The interface layer stays thin regardless of project size.

**When the count is honestly wrong, record it — don't fake it.** The doc carve-out
above proves the invariant admits exceptions and that the way to take one is to name
it. Cross-cutting concerns — auth middleware, a logging interceptor, a DI wiring point
— legitimately touch more files. Say so in the design doc's decision log and move on.
What you must not do is satisfy the count by hiding the third and fourth call sites
behind an indirection: that trades a stated exception for a worse structure, and the
count was a proxy for the structure in the first place.

**Keep call sites findable by grep.** The invariant bounds how many files a feature
touches and says nothing about whether the next reader — or a tool — can find them.
Dynamic dispatch on a constructed name, a registry keyed by a string built at runtime,
a re-export that renames as it passes through: each one makes a call site invisible to
search, so a class of bug becomes uncountable and the mechanical check that would close
it cannot be written. Prefer the form a grep finds. Where you need indirection, keep one
literal table mapping key to target, so the table is the thing you search.

**A dispatcher enforces its own contract.** Once `features/` has more than a couple of
modules competing for one input, state what an extension may not do to shared state and
have the dispatcher assert it rather than trusting each extension. Keep ordering an
explicit priority value, never registration order. And keep two failures distinct:
**nobody claimed this input** and **a claimant threw** are different bugs, and a
dispatch error that names every candidate it tried turns a silent no-op into a
one-line diagnosis. Below three candidates per input this is overhead — one handler
per key has no ambiguity to resolve.

**Manifest language examples:**
| Type | Interface | Engine | Features |
|------|-----------|--------|----------|
| Python | `__init__.py` (schemas + dispatch) | `backend.py` | `summaries.py` |
| Go | `cmd/main.go` + `api/*.go` | `internal/engine.go` | `internal/features/*.go` |
| TypeScript | `index.ts` (exports + types) | `src/core/engine.ts` | `src/modules/*.ts` |
| Rust | `src/main.rs` (clap + commands) | `src/engine.rs` | `src/features/*.rs` |
| JS/Node | `plugin.js` (SDK hooks) | `lib/engine.js` | `lib/features/*.js` |
