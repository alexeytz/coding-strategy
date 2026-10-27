# 3 Configuration

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

Configuration layers, what gets externalized, and seeing which layer won. Making a checkout
runnable is [4](04-setup-and-dependencies.md); where code goes is [2](02-layout.md).

**Rules**

- Structural config goes in JSON/YAML, host config in `.env`; precedence is env var > config file > default, but an explicit argument the environment contradicts is refused, not overridden (3.1)
- Document every variable in `.env.example` with REQUIRED/OPTIONAL and its default; placeholders only, never secrets (3.1)
- With more than two config layers, print which layer won for each value; keep authored and effective config as two objects (3.2)
- A value an agent writes to a shadowed layer is persisted and inert - write to the winning layer or refuse (3.3)
- Multi-tenant in one process: the tenant goes in the cache key and in anything constructed once or read at import (3.4)
- Regexes, prompts, thresholds and entity lists live in `config/` data files, never as literals in code (3.5)
- A config file you could not read is never overwritten; a missing data file fails loudly, with no fallback literal in code (3.6)

### 3.1 Config split

Structural config (JSON/YAML) vs environment config (.env). Env vars win over config files.

- **JSON/YAML:** collections, scoring weights, feature flags - rarely changes
- **.env:** URLs, model names, paths, API keys - changes per host/environment
- Explicit priority: env vars > JSON config > hardcoded defaults
- **Not over an explicit argument.** When a caller passes a value (a path, a database, a target)
  and the environment names a different one, refuse with both values in the message; never let
  the environment win silently. One project's database-path variable beating an explicit path
  caused five wrong-database incidents; in the last, a test driver deleted live vectors while
  the warning was on screen
- Document all env vars with required/optional markers and defaults

**Never commit secrets.** Ship `.env.example` with placeholder values.

### 3.2 Make the resolution observable

Stating precedence is not the same as being able to see it. Three rules, each paid for:

- **Print which layer won.** For every layered value, the resolved source at startup or
  behind a flag. Without it, "why is this value 512?" is answered by reading source, and
  a layer that silently never applies looks identical to one that agrees. The payoff
  scales with the number of layers; for `.env` over a default it is overhead.
- **Keep authored and effective config as two objects**, not one merged blob - you
  cannot diff what a user set against what the system decided once they are the same
  dict.
- **The config reference is derived, not maintained.** `.env.example` listing every
  variable with REQUIRED/OPTIONAL and its default is this skill's own rule with nothing
  checking it. Where config is declared in code, generate the reference from the
  declarations and assert every field has a default and a description. Where config is
  a flat `.env` read by bare env lookups there is no declaration site, and building one
  just to enable the check inverts the cost - then keep it by hand and know it drifts.

### 3.3 The layer an agent can write is the layer that loses

Precedence cuts both ways: if
an agent writes a value into the config file while an env var sets the same key, its
write is real, persisted, and has no effect. It will not notice. Either let runtime
writes go to the layer that wins, or refuse the write and say which layer is shadowing
it.

### 3.4 One process serving several configurations breaks two things quietly

A singleton
built from the first configuration it saw, and a cache keyed without the tenant in the
key. Both return the wrong tenant's answer rather than failing. If one process serves
more than one configuration, the tenant belongs in the cache key and in the identity of
anything constructed once or read at import: a log path and level read when the module loaded
are shared by every configuration the process later serves.

### 3.5 Externalize configurables

Regex patterns, prompts, thresholds, entity definitions, scoring weights - store as data files, never hardcoded.

**Why:**
- Keeps code clean (no 20-line regex literals in Python)
- Users/customers can tweak without editing source
- Version-controlled alongside code
- Hot-reloadable in many cases

**Common patterns:**
- `config/patterns/*.json` - regex patterns, entity definitions
- `config/prompts/*.md` - LLM prompts, templates
- `config/defaults.yaml` - thresholds, timeouts, limits

**Convention:** ship a `default.*` file. Users copy to `custom.*` to override. Never edit `default.*` directly.
Comment it only where the format allows comments (YAML, TOML); JSON has none, so explain a
JSON default in a README beside it. Test the documented copy: in one project the example
config's `#` lines made the printed `cp` produce a file that did not parse.

### 3.6 A config you could not read is the user's, not yours

When a config file fails to parse, stop and say so; never replace it with defaults. In the
project above, the plugin met the unparseable copy and overwrote the user's file with its
defaults. And a data file with a fallback literal in code is two definitions of one thing: when
a build dropped the data file, the literal, long since drifted, took over without a word, and
the published package measured worse than the tree it was built from. Load the file or fail.
