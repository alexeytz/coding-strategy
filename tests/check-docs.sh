#!/usr/bin/env bash
# Doc-consistency checks for the coding-strategy skill.
# This repo ships no code, so its testable invariants are structural: links resolve,
# the SKILL.md routing table matches the files on disk, and nothing is duplicated
# across files. Run from anywhere: tests/check-docs.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

PASS=0; FAIL=0
ok()  { printf '  \033[32mPASS\033[0m  %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAIL=$((FAIL+1)); [ -n "${2:-}" ] && printf '%b\n' "$2"; }
mds() { find . -name '*.md' -not -path './.git/*' | sort; }

echo "coding-strategy doc checks — $ROOT"
echo

# --- 1. Every relative markdown link resolves ------------------------------
errs=""
while IFS= read -r f; do
  d="$(dirname "$f")"
  while IFS= read -r link; do
    case "$link" in http*|mailto:*|'#'*|'') continue ;; esac
    tgt="${link%%#*}"; [ -z "$tgt" ] && continue
    [ -e "$d/$tgt" ] || errs="$errs\n    $f -> $link"
  done < <(grep -o '](\([^)]*\))' "$f" | sed 's/^](//; s/)$//')
done < <(mds)
[ -z "$errs" ] && ok "T1 all relative markdown links resolve" \
              || bad "T1 broken markdown links" "$errs"

# --- 2. SKILL.md routing table matches references/ on disk -----------------
listed="$(grep -o 'references/phase-[a-z0-9-]*\.md' SKILL.md | sort -u)"
ondisk="$(ls references/phase-*.md | sort -u)"
if [ "$listed" = "$ondisk" ]; then
  ok "T2 SKILL.md routing table matches references/ ($(echo "$ondisk" | wc -l) phases)"
else
  bad "T2 SKILL.md table and references/ disagree" \
      "$(diff <(echo "$listed") <(echo "$ondisk") | sed 's/^/    /')"
fi

# --- 3. SKILL.md frontmatter is valid and self-describing ------------------
fm_errs=""
head -1 SKILL.md | grep -q '^---$' || fm_errs="$fm_errs\n    missing opening ---"
grep -q '^name: coding-strategy$' SKILL.md || fm_errs="$fm_errs\n    missing or wrong name:"
grep -q '^description:' SKILL.md || fm_errs="$fm_errs\n    missing description:"
# description must state when to use, not just what it contains
grep -qi '^  Use when' SKILL.md || fm_errs="$fm_errs\n    description does not state activation conditions"
[ -z "$fm_errs" ] && ok "T3 SKILL.md frontmatter valid" || bad "T3 SKILL.md frontmatter" "$fm_errs"

# --- 4. Section numbering 1..15 continuous and unique across phases --------
nums="$(grep -ho '^### [0-9]\+\.' references/phase-*.md | tr -d '#. ' | sort -n)"
want="$(seq 1 25)"
if [ "$nums" = "$want" ]; then
  ok "T4 sections 1-$(echo "$want" | tail -1) present exactly once across phase files"
else
  bad "T4 section numbering broken" "$(diff <(echo "$want") <(echo "$nums") | sed 's/^/    /')"
fi

# --- 5. Every phase file carries the nav header ----------------------------
errs=""
for f in references/phase-*.md; do
  head -20 "$f" | grep -q 'Other phases:' || errs="$errs\n    $f missing nav header"
  head -1 "$f" | grep -qE '^# Phase [0-9]+[a-z]?:' \
    || errs="$errs\n    $f H1 is not '# Phase <n>[a-z]: <title>' (got: $(head -1 "$f"))"
done
[ -z "$errs" ] && ok "T5 phase files have H1 + nav header" || bad "T5 phase headers" "$errs"

# --- 6. Human-facing guide stays out of the agent load path ----------------
if [ -f operator-guide.md ] && [ ! -e references/operator-guide.md ]; then
  ok "T6 operator-guide.md is outside references/"
else
  bad "T6 operator-guide.md must exist at repo root and NOT in references/"
fi

# --- 7. Copyable assets referenced by the docs exist -----------------------
errs=""
for f in config/AGENTS.root.template.md config/AGENTS.child.template.md \
         operator-guide.md references/project-checklist.md \
         config/pre-commit-secret-scan.sh config/gitleaks.default.toml config/env.example \
         config/feature-tracker.template.md config/doc-update-matrix.template.md; do
  [ -e "$f" ] || errs="$errs\n    missing: $f"
done
[ -z "$errs" ] && ok "T7 all shipped templates present" || bad "T7 missing templates" "$errs"

# --- 8. No prompt text duplicated across files -----------------------------
errs=""
while IFS='|' read -r label needle; do
  n="$(grep -rl "$needle" --include='*.md' . | wc -l)"
  [ "$n" -eq 1 ] || errs="$errs\n    '$label' appears in $n files (must be 1)"
done <<'NEEDLES'
interview prompt|Act as a technical interviewer
AGENTS.md bootstrap prompt|Build the AGENTS.md hierarchy for this repo
NEEDLES
[ -z "$errs" ] && ok "T8 no prompt duplicated across files" || bad "T8 duplicated prompts" "$errs"

# --- 9. TODO markers only in the AGENTS.md templates -----------------------
# A marker is a TODO: opening a line (the template fill-in convention). Prose that
# mentions `TODO:` inline or inside a table cell is not a marker. The exemption is
# keyed on the `config/*.template.md` naming convention rather than a list of paths,
# so a new template does not need an edit here — but it stays confined to config/,
# because bug 10 was a blank template sitting at the repo root where the exemption
# hid the fact that the repo had no context doc of its own.
stray="$(grep -rln '^[[:space:]]*-\?[[:space:]]*TODO:' --include='*.md' . \
         | grep -v '^./config/[A-Za-z.-]*\.template\.md$')"
[ -z "$stray" ] && ok "T9 TODO: markers confined to AGENTS templates" \
               || bad "T9 stray TODO: markers" "$(echo "$stray" | sed 's/^/    /')"

# --- 10. Shipped shell assets are syntactically valid ----------------------
errs=""
for f in $(find . -name '*.sh' -not -path './.git/*'); do
  bash -n "$f" 2>/dev/null || errs="$errs\n    syntax error: $f"
done
[ -z "$errs" ] && ok "T10 shell assets parse" || bad "T10 shell syntax" "$errs"

# --- 11. No reference file exceeds the per-load size budget ------------------
# The point of the phase split is that one trigger loads one modest file.
# ~4 bytes/token: 10000B ~ 2500 tokens is the hard ceiling; 8000B ~ 2000 warns.
# A warning is advisory (split it by job when convenient) and does not fail the run.
# rules-card.md is exempt by design: it is not one job, it is every phase at once,
# so its budget is relative and T13 owns it.
errs=""; warns=""
for f in references/*.md; do
  case "$f" in references/rules-card*.md) continue ;; esac
  sz=$(wc -c < "$f")
  if   [ "$sz" -gt 10000 ]; then errs="$errs\n    $f is ${sz}B (ceiling 10000B) — split it by job"
  elif [ "$sz" -gt 9500  ]; then warns="$warns\n    $f is ${sz}B — PAST THE 9500B REVISIT THRESHOLD, split it by job now"
  elif [ "$sz" -gt 8000  ]; then warns="$warns\n    $f is ${sz}B (advisory 8000B)"
  fi
done
if [ -n "$errs" ]; then bad "T11 oversized reference files" "$errs"
else
  ok "T11 all reference files within size budget"
  [ -n "$warns" ] && printf '  \033[33mWARN\033[0m  approaching the budget:%b\n' "$warns"
fi

# --- 12. The rules cards cover every phase between them ---------------------
# A card is only safe to load *instead of* a phase file if the set summarises all of
# them. Split in two on 2026-09-13: one card could not stay under T13's ceiling once
# the strategy reached 19 phase files, and shaving it was deleting load-bearing rules.
# Coverage is asserted over the union, so a phase may be summarised in either card.
errs=""
for f in references/phase-*.md; do
  b="$(basename "$f")"
  grep -qh "($b)" references/rules-card*.md || errs="$errs\n    no rules card links $b"
done
[ -z "$errs" ] && ok "T12 rules cards cover every phase file" || bad "T12 rules card coverage" "$errs"

# --- 13. Rules card stays materially cheaper than the phases it replaces ----
# Two bounds, because the card is exempt from T11: relative (it must stay a
# fraction of what it replaces) and absolute (a card nobody can afford to load
# is not a card, however many phases exist to justify it).
# The ceiling is per card, not for the set: the point is that ONE card is loadable
# instead of a phase file, and a reader loads the half their job is in.
phases=$(cat references/phase-*.md | wc -c)
total=$(cat references/rules-card*.md | wc -c)
CARD_MAX=11000
errs=""
for c in references/rules-card*.md; do
  sz=$(wc -c < "$c")
  [ "$sz" -gt "$CARD_MAX" ] && errs="$errs\n    $(basename "$c") is ${sz}B, ceiling ${CARD_MAX}B — one line per rule, no rationale"
done
if [ -n "$errs" ]; then bad "T13 a rules card exceeds its absolute budget" "$errs"
elif [ $((total * 3)) -ge "$phases" ]; then
  bad "T13 rules cards have grown too close to the phase files" \
      "    cards ${total}B vs phases ${phases}B — strip rationale or drop rules"
else
  ok "T13 rules cards total ${total}B vs ${phases}B of phase files ($((100 * total / phases))%, ceiling ${CARD_MAX}B each)"
fi

# --- 14. Every backlog item carries a decided status -----------------------
# A backlog is only worth keeping if an item cannot leave it silently. Each
# `### B<n>` heading must be followed by a Status line holding one of three
# values, so "absorbed" and "declined" are recorded rather than deleted — the
# same reason phase-7b makes a findings header write `unknown` over a blank.
if [ -f backlog.md ]; then
  errs=""
  ids="$(grep -c '^### B[0-9]' backlog.md)"
  sts="$(grep -c '^\*\*Status:\*\* \(open\|absorbed\|declined\)$' backlog.md)"
  [ "$ids" -gt 0 ] || errs="$errs\n    backlog.md exists but declares no ### B<n> items"
  [ "$ids" -eq "$sts" ] || errs="$errs\n    $ids items but $sts valid Status lines (open|absorbed|declined)"
  [ -z "$errs" ] && ok "T14 backlog items all carry a decided status ($ids items)" \
                 || bad "T14 backlog status integrity" "$errs"
else
  ok "T14 no backlog.md (nothing to check)"
fi

# --- 15. Prose "phase-N §M" pointers name a file that exists and holds §M ---
# Suffix and digit are [0-9]+[a-z]? deliberately. Both were once enumerated to
# exactly what existed — [1-8] until bug 14, [a-c] until the 7c/7d split — and each
# time the enum was widened only after it bit. T5's version FAILED loudly on the
# unlisted suffix; this one PASSED, because a pointer it cannot parse is a pointer
# it does not check. A guard that fails open is the B20 shape. Don't re-narrow these.
# T1 only sees markdown links. The phase-2 split renamed a file whose sections were
# cited in prose across five files, and nothing caught it — the same class the phase-3
# split had to sweep by hand. Second occurrence, so it gets a check (phase-2b §6).
# designs/ is excluded: a design doc is decision history and cites the phase names that
# were current when it was written.
errs=""
while IFS=: read -r f ref; do
  id="$(echo "$ref" | sed 's/^phase[- ]//; s/ *§.*//')"
  sec="$(echo "$ref" | sed 's/.*§//')"
  tgt="$(ls references/phase-"$id"-*.md 2>/dev/null | head -1)"
  if [ -z "$tgt" ]; then
    errs="$errs\n    $f cites '$ref' — no references/phase-$id-*.md exists"
  elif ! grep -q "^### $sec\." "$tgt"; then
    errs="$errs\n    $f cites '$ref' — §$sec is not in $(basename "$tgt")"
  fi
done < <(grep -rno 'phase[- ][0-9]\+[a-z]\? *§[0-9]\+' --include='*.md' . \
         | grep -v '^./designs/' | sed 's/:[0-9]*:/:/' | sort -u)
[ -z "$errs" ] && ok "T15 prose section pointers resolve to the right phase file" \
               || bad "T15 stale phase §-pointers" "$errs"

# --- 16. The artifacts AGENTS.md forbids by name are absent ---------------
# Every other case asserts that a file we know about is well-formed. None asserted
# that a forbidden file is ABSENT, so on 2026-09-11 an agent commissioned to audit
# this repo created sessions.txt — named in AGENTS.md's Negative Constraints, and
# in handover.md twice more — and the suite passed. Backlog B64.
# Deliberately only the three artifacts AGENTS.md already names. A denylist grows
# one row per incident and never shrinks; this one tracks that sentence, nothing
# more. If AGENTS.md stops naming one, delete it here too.
# Three tiers, because "this file exists" covers three different situations.
#   TRACKED              — apparatus entered the repo. What AGENTS.md forbids. Hard fail.
#   untracked, NOT ignored — one `git add -A` from being committed by accident. Warn.
#   untracked and IGNORED  — deliberately excluded, which is the correct handling. Silent.
# The third tier exists because the HLM plugin appends sessions.txt to every git project it
# runs in, as a local lookup aid. That is a tool doing its job, and a guard that fires on the
# correct handling of it is noise — which is how a suite teaches people to ignore its output.
errs=""; warns=""
for forbidden in sessions.txt ta docs/context-index.md; do
  [ -e "$forbidden" ] || continue
  if git ls-files --error-unmatch "$forbidden" >/dev/null 2>&1; then
    errs="$errs\n    $forbidden is TRACKED — AGENTS.md Negative Constraints forbids it by name"
  elif ! git check-ignore -q "$forbidden" 2>/dev/null; then
    warns="$warns\n    $forbidden is present and not ignored — gitignore it or delete it, do not commit it"
  fi
done
if [ -n "$errs" ]; then bad "T16 forbidden artifact committed" "$errs"
else
  ok "T16 Tier 3 apparatus AGENTS.md declines is not in the repo"
  [ -n "$warns" ] && printf '  \033[33mWARN\033[0m  untracked artifact in the working dir:%b\n' "$warns"
fi

if [ "${1:-}" = "--self-test" ]; then
  # B20 applied to this suite: a guard is not evidence until it has been seen to fail.
  # The controls were each run once when their case was written; bugs 14, 17 and 18 are
  # what that costs — two enums silently stopped matching, and one of them still said PASS.
  echo; echo "--- self-test: each guard must FAIL on a seeded break ---"
  st_fail=0
  probe() { # name, setup-command
    d="$(mktemp -d)/r"; cp -r . "$d" 2>/dev/null
    ( cd "$d" && eval "$2" && bash tests/check-docs.sh >/dev/null 2>&1 )
    if [ $? -ne 0 ]; then printf '  \033[32mOK\033[0m    %s fails when broken\n' "$1"
    else printf '  \033[31mBAD\033[0m   %s still PASSES when broken\n' "$1"; st_fail=$((st_fail+1)); fi
    rm -rf "$(dirname "$d")"
  }
  probe "T1  link"        "echo '[x](references/nope.md)' >> SKILL.md"
  probe "T4  section"     "sed -i 's/^### 25\\./### 99./' references/phase-10-data-architecture.md"
  probe "T5  H1"          "sed -i '1s/.*/# Nope/' references/phase-6-reference.md"
  probe "T9  TODO"        "printf 'TODO: x\\n' >> AGENTS.md"
  probe "T10 shell"       "printf 'if then fi(\\n' >> config/pre-commit-secret-scan.sh"
  probe "T11 size"        "python3 -c \"open('references/phase-6-reference.md','a').write('x'*11000)\""
  probe "T14 status"      "printf '\\n### B999 — probe\\n\\nno status line\\n' >> backlog.md"
  # Safe to spell literally here: T15 scans *.md only, and this is a shell script.
  probe "T15 pointer"     "printf '\\nSee phase-6 \u00a799 here.\\n' >> references/phase-6-reference.md"
  probe "T16 forbidden"   "touch sessions.txt && git add -f sessions.txt"
  echo
  [ "$st_fail" -eq 0 ] && echo "self-test: all guards bite" || echo "self-test: $st_fail guard(s) did not fire"
  exit $([ "$st_fail" -eq 0 ] && echo 0 || echo 1)
fi

echo
printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
