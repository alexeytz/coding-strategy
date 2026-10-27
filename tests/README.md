# tests/

These scripts check the skill itself, not your project. You need them only if you edit the
skill, fork it, or want to confirm a copy is intact. A project that adopts the skill copies
nothing from here; its copy targets are in [`config/`](../config/README.md).

Both run anywhere with bash, coreutils and Python 3. No network, no install.

### `check-docs.sh`

**The problem.** The skill is about forty documents that point at each other: `SKILL.md` routes to
the numbered files, rules cite rules by number (`see 13.2`), the cards repeat each file's rule
summary, and `config/` scripts name the rules they enforce. Edit one file and a citation
elsewhere goes stale without anyone noticing, and an agent that follows it lands on the wrong
rule. A file that grows past its size budget stops being cheap to load on its own, which is the
point of the layout.

**What it does.** It checks what can be checked mechanically, about two dozen cases: every link
resolves, the routing table in `SKILL.md` matches the files on disk, every rule `N.M` exists
once and every citation of it lands on it, every numbered file stays under 8,000 bytes, the
cards match what `build-cards.sh` would generate, each `config/` script parses and passes its own
`--self-test`, and a few specific sentences the tests showed matter are still there. It prints
each case as PASS or FAIL and exits non-zero on any failure.

```sh
tests/check-docs.sh               # run the checks
tests/check-docs.sh --self-test   # break each check on purpose in a copy, and require it to fail
```

**Why `--self-test`.** A check that has silently stopped matching still says PASS. Three of this
skill's own bugs were checks like that, one of them passing on input it could not parse. The
self-test copies the tree, seeds one break per check, and reports any check that does not catch
it. Run it after changing a check.

### `build-cards.sh`

**The problem.** The two rules cards (`references/rules-card.md` for building,
`references/rules-card-operating.md` for everything else) let an agent with a tight context load
one page instead of the files. Kept by hand, they drifted from the files they summarise: lines
for rules that had changed, groups out of order, empty groups.

**What it does.** It builds both cards from the **Rules** block at the top of each numbered file,
so a card is never edited directly. Edit a file's Rules block, then run it. With `--check` it
only reports whether the cards are current, which `check-docs.sh` uses.

```sh
tests/build-cards.sh           # rewrite both cards
tests/build-cards.sh --check   # exit 1 if either card is out of date
```

Which file goes on which card is the two lists at the top of the script. A new numbered file goes
on one of them.
