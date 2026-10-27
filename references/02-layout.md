# 2 Layout

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Where code goes, and what keeps it findable. Configuration is [3](03-configuration.md); the setup scripts
are [4](04-setup-and-dependencies.md).

**Rules**

- `interface/` holds types, schemas, dispatch and routing, nothing else; `engine/` holds logic and integrations; `features/` one module per capability (2.1)
- A feature touches at most 2 source files; needing 5 means the interface is wrong - fix that, don't spread the feature; doc updates do not count (2.2)
- Record an honest over-count in the design doc; never hide call sites behind indirection to satisfy it (2.3)
- Keep call sites greppable - no names built at runtime; one literal table when you need indirection (2.4)
- Once several modules compete for one input, the dispatcher asserts the contract, orders by an explicit priority, never registration order, and names every candidate it tried (2.5)

### 2.1 Interface / engine / features

Thin public API, fat internal engine, pluggable feature modules.

```
project/
  interface/       # Types, schemas, dispatch, routing - NOTHING else
  engine/          # Core logic, pipelines, CRUD, external integrations
  features/        # One module per capability (summaries, export, ingest, ...)
  config/          # Data files: patterns, thresholds, defaults
  tests/           # Test runners + living test plan
```

The two-file invariant (2.2) is also a working-set bound: it caps how much a reader - human or model - must
hold at once to change one thing. See [29.3](29-small-models.md).

### 2.2 A feature touches at most two source files

One feature touches at most 2 *source* files (interface schema + engine
method). Never 5 source files for one feature - needing 5 means the interface is wrong; fix that, don't spread the feature. Doc updates (AGENTS.md, handover, design
doc) are not counted - they are expected on top. The interface layer stays thin regardless of project size.

### 2.3 When the count is honestly wrong, record it - don't fake it

The doc carve-out
above proves the invariant admits exceptions and that the way to take one is to name
it. Cross-cutting concerns - auth middleware, a logging interceptor, a DI wiring point -
legitimately touch more files. Say so in the design doc's decision log and move on.
What you must not do is satisfy the count by hiding the third and fourth call sites
behind an indirection: that trades a stated exception for a worse structure, and the
count was a proxy for the structure in the first place.

### 2.4 Keep call sites findable by grep

The invariant bounds how many files a feature
touches and says nothing about whether the next reader - or a tool - can find them.
Dynamic dispatch on a constructed name, a registry keyed by a string built at runtime,
a re-export that renames as it passes through: each one makes a call site invisible to
search, so a class of bug becomes uncountable and the mechanical check that would close
it cannot be written. Prefer the form a grep finds. Where you need indirection, keep one
literal table mapping key to target, so the table is the thing you search.

### 2.5 A dispatcher enforces its own contract

Once `features/` has more than a couple of
modules competing for one input, state what an extension may not do to shared state and
have the dispatcher assert it rather than trusting each extension. Keep ordering an
explicit priority value, never registration order. And keep two failures distinct:
**nobody claimed this input** and **a claimant threw** are different bugs, and a
dispatch error that names every candidate it tried turns a silent no-op into a
one-line diagnosis. Below three candidates per input this is overhead - one handler
per key has no ambiguity to resolve.

### 2.6 Manifest examples by language

| Type | Interface | Engine | Features |
|------|-----------|--------|----------|
| Python | `__init__.py` (schemas + dispatch) | `backend.py` | `summaries.py` |
| Go | `cmd/main.go` + `api/*.go` | `internal/engine.go` | `internal/features/*.go` |
| TypeScript | `index.ts` (exports + types) | `src/core/engine.ts` | `src/modules/*.ts` |
| Rust | `src/main.rs` (clap + commands) | `src/engine.rs` | `src/features/*.rs` |
| JS/Node | `plugin.js` (SDK hooks) | `lib/engine.js` | `lib/features/*.js` |
