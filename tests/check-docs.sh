#!/usr/bin/env bash
# Doc-consistency checks for the coding-strategy skill.
# Why: the skill is documents that cite each other by number, and an edit in one silently
# breaks a citation in another. The invariants are structural: links resolve, the SKILL.md
# routing table matches the files on disk, every cited rule exists, the config/ scripts pass
# their self-tests. More: tests/README.md. Run from anywhere: tests/check-docs.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

PASS=0; FAIL=0
ok()  { printf '  \033[32mPASS\033[0m  %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAIL=$((FAIL+1)); [ -n "${2:-}" ] && printf '%b\n' "$2"; }
# says FILE TEXT: a paragraph of FILE contains TEXT verbatim, line wraps read as spaces. For a
# measured sentence: a topic phrase as the anchor passed rewordings that inverted the instruction
# (round 15). Paragraphs are joined one at a time: joining across a blank line passed a sentence
# split into a bullet and a loose paragraph (round 16).
# A line of only spaces or tabs is a blank line to a markdown renderer, so it is made empty before
# awk's paragraph mode reads it: mawk joined across one (round 17).
paras() { sed -E 's/^[[:blank:]]+$//' | awk 'BEGIN{RS=""} {gsub(/[ \t]*\n[ \t]*/, " "); print}' | tr -s ' '; }
# Never `| grep -q` under pipefail: grep -q exits at the first match, the writer upstream takes
# SIGPIPE, and the pipeline fails on text it found - 29 of 400 early matches (cold read, 2026-10-26).
says() { paras < "$1" | grep -F -- "$2" >/dev/null; }
# rule_says FILE N.M TEXT: the same, inside rule N.M only. A file-wide grep passed a pointer moved
# out of the rule it belongs to (round 16), as T5's did (bug 31).
# Fenced lines are skipped, as T4's and T5's extractors skip them (bug 31): a fenced `###` ended the
# rule early, and a fenced example satisfied the check for prose that had dropped it (round 17).
# A rule ends at the next heading of any level, as a renderer ends it: a `## ` after the last
# rule was read as that rule's text (round 17).
rule_body() { awk -v h="### $2 " '/^```/ {f = !f; next} f {next}
  index($0, h) == 1 {on = 1; next} on && /^#+ / {exit} on' "$1"; }
rule_says() { rule_body "$1" "$2" | paras | grep -F -- "$3" >/dev/null; }
# reviews/ holds outside reviewers' findings files: git-ignored, quoting the tree rather than
# part of it, so a quoted broken link or TODO there must not fail the suite the reviewer is testing.
mds() { find . -name '*.md' -not -path './.git/*' -not -path './reviews/*' | sort; }

echo "coding-strategy doc checks - $ROOT"
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
listed="$(grep -o 'references/[0-9][0-9]-[a-z0-9-]*\.md' SKILL.md | sort -u)"
ondisk="$(ls references/[0-9][0-9]-*.md | sort -u)"
if [ "$listed" = "$ondisk" ]; then
  ok "T2 SKILL.md routing table matches references/ ($(echo "$ondisk" | wc -l) files)"
else
  bad "T2 SKILL.md table and references/ disagree" \
      "$(diff <(echo "$listed") <(echo "$ondisk") | sed 's/^/    /')"
fi

# --- 3. SKILL.md frontmatter is valid and self-describing ------------------
fm_errs=""
head -1 SKILL.md | grep '^---$' >/dev/null || fm_errs="$fm_errs\n    missing opening ---"
grep -q '^name: coding-strategy$' SKILL.md || fm_errs="$fm_errs\n    missing or wrong name:"
grep -q '^description:' SKILL.md || fm_errs="$fm_errs\n    missing description:"
# description must state when to use, not just what it contains
grep -qi '^  Use when' SKILL.md || fm_errs="$fm_errs\n    description does not state activation conditions"
# Its first sentence must fit in 57 characters. Hermes shows a model only the description's first
# 57 characters in the skill index; under it, with an opening about new projects, two models
# opened this skill 4 times in 32 tasks, against 22 in 32 under an agent that showed all of it
# (eval/TESTS.md, test 15). The opening sentence is the whole routing signal there.
first="$(awk '/^description: >/{f=1;next} f&&/^  /{sub(/^  /,"");printf "%s ",$0;next} f{exit}' SKILL.md \
  | sed -E 's/\. .*/./; s/ +$//')"
[ "${#first}" -le 57 ] || fm_errs="$fm_errs\n    description's first sentence is ${#first} chars; Hermes shows 57: '$first'"
[ -z "$fm_errs" ] && ok "T3 SKILL.md frontmatter valid" || bad "T3 SKILL.md frontmatter" "$fm_errs"

# --- 4. Files run 01..N; rules run N.1..N.k inside each file ----------------
# The file count is hardcoded on purpose: derived from the files it checks, it would pass on a
# dropped trailing file. Adding a file means raising it here - read N here, not from a doc.
# Inside a file, every ### heading outside a code fence is a rule "N.M Title" with N the file's
# own number and M running 1..k with no gap. New rules append, so numbers never shift.
FILES=37
errs=""
have="$(ls references/[0-9][0-9]-*.md | sed 's|references/||; s/-.*//' | sed 's/^0//')"
[ "$have" = "$(seq 1 $FILES)" ] || errs="$errs\n    files are not 01..$FILES: $(echo $have)"
for f in references/[0-9][0-9]-*.md; do
  n=$(basename "$f" | sed 's/-.*//; s/^0//')
  bad_h="$(awk -v n="$n" '
    /^```/ { fence = !fence; next }
    fence { next }
    /^### / { k++; if ($0 !~ "^### " n "\\." k " [^ ]") print "    " FILENAME ": expected " n "." k ", got: " $0 }
    END { if (k == 0) print "    " FILENAME ": no N.M rules" }' "$f")"
  [ -n "$bad_h" ] && errs="$errs\n$bad_h"
done
[ -z "$errs" ] && ok "T4 files 01-$FILES present; rules numbered N.1..N.k in each" \
               || bad "T4 numbering broken" "$errs"

# --- 5. Every numbered file opens the same way, and its rules cite its own N.M --------
# Title, the SKILL.md line, then a Rules block before the first rule. Each Rules line ends with
# the N.M it summarises, and that N.M must exist in the file - a card line pointing at a rule
# that moved is the stale-pointer class again, one level down.
errs=""
for f in references/[0-9][0-9]-*.md; do
  n=$(basename "$f" | sed 's/-.*//; s/^0//')
  head -1 "$f" | grep -E "^# $n [A-Z]" >/dev/null || errs="$errs\n    $f: H1 is not '# $n <Title>'"
  sed -n 3p "$f" | grep 'routing table in \[SKILL.md\](../SKILL.md)' >/dev/null || errs="$errs\n    $f: line 3 is not the SKILL.md line"
  # A rule is what T4 counts: a ### heading outside a code fence. One extractor for both, so a
  # heading inside an example fence cannot back a Rules line that T4 never numbered (bug 31).
  heads="$(awk '/^```/ {fence=!fence; next} !fence && /^### / {print $2}' "$f")"
  first="$(awk '/^```/ {fence=!fence; next} fence {next} /^\*\*Rules\*\*$/ {print "rules"; exit} /^### / {print "rule"; exit}' "$f")"
  [ "$first" = "rules" ] || { errs="$errs\n    $f: no Rules block before the first rule"; continue; }
  rules="$(awk '/^\*\*Rules\*\*$/ {on=1; next} on && /^### / {exit} on && /^- / {print}' "$f")"
  [ -n "$rules" ] || { errs="$errs\n    $f: Rules block is empty"; continue; }
  while IFS= read -r line; do
    refs="$(echo "$line" | grep -oE '\([0-9]+\.[0-9]+([–,] ?[0-9]+\.[0-9]+)*\)$')"
    [ -n "$refs" ] || { errs="$errs\n    $f: rules line has no trailing (N.M): ${line:0:60}"; continue; }
    for r in $(echo "$refs" | grep -oE '[0-9]+\.[0-9]+'); do
      echo "$heads" | grep -xF "$r" >/dev/null || errs="$errs\n    $f: rules line cites $r, which is not a rule in this file"
    done
  done <<< "$rules"
done
[ -z "$errs" ] && ok "T5 numbered files open with title, SKILL line and a Rules block citing their own rules" \
               || bad "T5 file headers and Rules blocks" "$errs"

# --- 6. Human-facing guide stays out of the agent load path ----------------
if [ -f operator-guide.md ] && [ ! -e references/operator-guide.md ]; then
  ok "T6 operator-guide.md is outside references/"
else
  bad "T6 operator-guide.md must exist at repo root and NOT in references/"
fi

# --- 7. Copyable assets referenced by the docs exist -----------------------
errs=""
for f in config/AGENTS.root.template.md config/AGENTS.child.template.md \
         operator-guide.md tests/build-cards.sh \
         config/pre-commit-secret-scan.sh config/pre-push-verify.sh \
         config/gitleaks.default.toml config/env.example \
         config/feature-tracker.template.md config/doc-update-matrix.template.md \
         config/guard-shrink.py config/safe-delete.sh config/delete-guard-hook.py; do
  [ -e "$f" ] || errs="$errs\n    missing: $f"
done
[ -z "$errs" ] && ok "T7 all shipped templates present" || bad "T7 missing templates" "$errs"

# --- 8. No prompt text duplicated across files -----------------------------
errs=""
while IFS='|' read -r label needle; do
  n="$(grep -rl "$needle" --include='*.md' --exclude-dir=reviews . | wc -l)"
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
# so a new template does not need an edit here - but it stays confined to config/,
# because bug 10 was a blank template sitting at the repo root where the exemption
# hid the fact that the repo had no context doc of its own.
stray="$(grep -rln '^[[:space:]]*-\?[[:space:]]*TODO:' --include='*.md' --exclude-dir=reviews . \
         | grep -v '^./config/[A-Za-z.-]*\.template\.md$')"
[ -z "$stray" ] && ok "T9 TODO: markers confined to AGENTS templates" \
               || bad "T9 stray TODO: markers" "$(echo "$stray" | sed 's/^/    /')"

# --- 10. Shipped shell assets are syntactically valid ----------------------
errs=""
for f in $(find . -name '*.sh' -not -path './.git/*'); do
  bash -n "$f" 2>/dev/null || errs="$errs\n    syntax error: $f"
done
# A mechanism is a claim that it refuses; config/ scripts that carry a --self-test prove it here, so
# a guard that stopped refusing fails the suite, not a project that trusted it (24.5, 24.4). The
# shipped mechanisms are named, not discovered: discovery by the string --self-test let one that
# lost or renamed its flag drop out of the suite silently (round nine). Others are still found.
MECHANISMS="config/guard-shrink.py config/safe-delete.sh config/delete-guard-hook.py"
for f in $MECHANISMS; do
  grep -q -- '--self-test' "$f" 2>/dev/null || errs="$errs\n    $f: no --self-test (a shipped mechanism must carry one)"
done
for f in config/*.sh config/*.py; do
  [ -f "$f" ] && grep -q -- '--self-test' "$f" || continue
  case "$f" in *.py) run=(python3 "$f") ;; *) run=(bash "$f") ;; esac
  "${run[@]}" --self-test >/dev/null 2>&1 || errs="$errs\n    $f --self-test fails"
done
# Bug 67: as root two cases cannot run, and the pass line must say so, or it claims what it skipped.
grep -qF 'skipped=" (as root: the two I/O-failure cases did not run' config/safe-delete.sh \
  && grep -qF 'all cases behave${skipped:-}' config/safe-delete.sh \
  || errs="$errs\n    config/safe-delete.sh: a root self-test no longer says two cases did not run (bug 67)"
[ -z "$errs" ] && ok "T10 shell assets parse; config mechanisms pass their self-tests" || bad "T10 shell syntax or mechanism self-test" "$errs"

# --- 11. No numbered file exceeds the per-load size limit --------------------
# One trigger loads one file, so a file is a per-load budget: 8000B ~ 2000 tokens. A hard limit,
# no advisory band - the band let four files sit over the line for weeks. Over it, split the file
# by job. The two cards are exempt: they are every file's Rules block at once, and T13 bounds them.
errs=""
for f in references/[0-9][0-9]-*.md; do
  sz=$(wc -c < "$f")
  [ "$sz" -gt 8000 ] && errs="$errs\n    $f is ${sz}B (limit 8000B) - split it by job"
done
[ -z "$errs" ] && ok "T11 every numbered file within 8000B" || bad "T11 oversized files" "$errs"

# --- 12. The cards are exactly the files' Rules blocks, each file on one card ----
# The cards used to be hand-kept, and drifted: empty groups, groups out of routing order, lines
# with no backing in their file. Now generated by tests/build-cards.sh; this asserts the
# generated text is what is committed, and that every file appears on exactly one card.
errs=""
tests/build-cards.sh --check >/dev/null 2>&1 || errs="$errs\n    a card differs from its sources - run tests/build-cards.sh"
for f in references/[0-9][0-9]-*.md; do
  b="$(basename "$f")"
  c=$(grep -l "^## .* - \[$b\]($b)$" references/rules-card*.md | wc -l)
  [ "$c" -eq 1 ] || errs="$errs\n    $b is on $c cards (must be 1)"
done
[ -z "$errs" ] && ok "T12 rules cards match the files' Rules blocks; each file on one card" \
               || bad "T12 rules cards" "$errs"

# --- 13. The cards stay materially cheaper than the files they replace ------------
# Relative bound only: the absolute ceiling forced cutting real rules three times, and with
# generated cards a long card means long Rules blocks, which T5 and review see where they live.
files=$(cat references/[0-9][0-9]-*.md | wc -c)
total=$(cat references/rules-card*.md | wc -c)
if [ $((total * 3)) -ge "$files" ]; then
  bad "T13 rules cards have grown too close to the files" "    cards ${total}B vs files ${files}B - tighten the Rules blocks"
else
  ok "T13 rules cards total ${total}B vs ${files}B of numbered files ($((100 * total / files))%)"
fi

# --- 14. Every backlog item carries a decided status -----------------------
# A backlog is only worth keeping if an item cannot leave it silently. Each
# `### B<n>` heading must be followed by a Status line holding one of three
# values, so "absorbed" and "declined" are recorded rather than deleted - the
# same reason 34.2 makes a findings header write `unknown` over a blank.
if [ -f backlog.md ]; then
  errs=""
  ids="$(grep -c '^### B[0-9]' backlog.md)"
  sts="$(grep -c '^\*\*Status:\*\* \(open\|absorbed\|declined\)$' backlog.md)"
  [ "$ids" -gt 0 ] || errs="$errs\n    backlog.md exists but declares no ### B<n> items"
  [ "$ids" -eq "$sts" ] || errs="$errs\n    $ids items but $sts valid Status lines (open|absorbed|declined)"
  # A decided item also says WHEN. Seven declined entries sat undated for six weeks
  # because nothing looked, and the dates had to be recovered from git rather than
  # read - a weaker fact than one written at the time. An undecided item has no date
  # to carry, so only absorbed and declined are checked.
  dec="$(grep -c '^\*\*Status:\*\* \(absorbed\|declined\)$' backlog.md)"
  dated="$(grep -c '^\*\*\(Absorbed\|Declined\):\*\* [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' backlog.md)"
  [ "$dec" -eq "$dated" ] || errs="$errs\n    $dec decided items but $dated carry an ISO date on an Absorbed:/Declined: line"
  open="$(grep -c '^\*\*Status:\*\* open$' backlog.md)"
  [ -z "$errs" ] && ok "T14 backlog items carry a decided status and a date ($ids items, $open open)" \
                 || bad "T14 backlog status integrity" "$errs"
else
  ok "T14 no backlog.md (nothing to check)"
fi

# --- 15. Citations resolve: a link labelled N or N.M lands on file N and rule N.M ----
# Every citation in the live docs is a link whose label is the number: [14](14-writing-tests.md) for
# a file, [14.3](14-writing-tests.md) for a rule. The label must match the file's prefix, and an N.M
# must exist there. Before the renumbering, five citation forms grew up and each escaped the
# guard of the day (bugs 11, 26, 27); one form now, and the old forms are banned outright from
# the live docs. designs/, backlog.md and the test plan are history and keep the old names.
LIVE="references SKILL.md README.md operator-guide.md config"
errs=""
while IFS= read -r hit; do
  f="${hit%%:*}"; rest="${hit#*:}"
  label="$(echo "$rest" | sed -E 's/^\[([0-9.]+)\].*/\1/')"
  # Read every digits-and-dots label, then refuse a malformed one: [6..99] was never selected (round 15).
  [[ "$label" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { errs="$errs\n    $f: [$label] - malformed citation"; continue; }
  tgt="$(echo "$rest" | sed -E 's/^\[[0-9.]+\]\((\.\.\/)?(references\/)?([0-9][0-9]-[a-z0-9-]+\.md)\)$/\3/')"
  n="${label%%.*}"
  [ "$(printf '%02d' "$n")" = "${tgt%%-*}" ] || { errs="$errs\n    $f: [$label] links $tgt"; continue; }
  case "$label" in *.*) grep -q "^### $label " "references/$tgt" || errs="$errs\n    $f: [$label] - no rule $label in $tgt" ;; esac
done < <(grep -rnoE '\[[0-9][0-9.]*\]\((\.\./)?(references/)?[0-9][0-9]-[a-z0-9-]+\.md\)' $LIVE \
           | sed -E 's/:[0-9]+:/:/')
# Shipped config assets are not markdown, and cite a rule as a bare N.M in prose: "Rule 13.2",
# "(12.3)", "Per 4.4", "half of 22.1." Every such token in any non-markdown file under config/
# must name a rule that exists. A number with a third part (8.30.1) is a version, and one whose
# file part is 0 (0.05) is not a rule; a leading zero (06.6) is resolved, not skipped. This loop
# once read only "phase N.M", which the ban below forbids (round nine), then needed grep -P and
# a fixed file list, so a BSD grep or a new .yaml was read as nothing (round ten). Plain ERE now,
# and a grep error fails the case rather than passing it.
# Whole runs of digits and dots, so no separator is consumed: a boundary-matching pattern ate
# the comma in "12.3,11.99" and never read the second citation (round eleven).
cfg_hits="$(grep -rnoE --exclude='*.md' '[0-9][0-9.]*' config)"
[ $? -le 1 ] || errs="$errs\n    config citation scan failed to run (grep error)"
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  f="${hit%%:*}"; ref="${hit#*:*:}"
  # Every trailing dot: "25.99..." still names 25.99, and one strip let it pass as a version (round twelve).
  while [ "${ref%.}" != "$ref" ]; do ref="${ref%.}"; done
  # An inner double dot is neither a rule nor a version, and was skipped as one (round 15).
  case "$ref" in *..*) errs="$errs\n    $f: $ref - malformed citation"; continue ;; esac
  [[ "$ref" =~ ^[0-9]+\.[0-9]+$ ]] || continue  # a bare number, or a version like 8.30.1
  n="$((10#${ref%%.*}))"; m="${ref#*.}"
  [ "$n" -eq 0 ] && continue
  [[ "$m" == 0[0-9]* ]] && continue  # a padded minor (1.02) is a version; no rule is numbered so (round thirteen)
  file="$(ls references/"$(printf '%02d' "$n")"-*.md 2>/dev/null)"
  if [ -z "$file" ]; then errs="$errs\n    $f: $ref - no such file"
  else grep -q "^### $n.$m " "$file" || errs="$errs\n    $f: $ref - no such rule"; fi
done <<< "$cfg_hits"
# The old schemes are gone from the live docs: a surviving one resolves to nothing or to the
# wrong file, and is exactly what the renumbering verified away.
# The space form counts too (bug 32), in config/ as much as in markdown; assets cite a bare N.M,
# checked above.
old="$( { grep -rnE 'phase-[0-9]|§' $LIVE; grep -rniE '\bphases? [0-9]' $LIVE; } \
        | grep -v '^references/rules-card' || true)"
[ -n "$old" ] && errs="$errs\n$(echo "$old" | sed 's/^/    old-scheme citation: /')"
[ -z "$errs" ] && ok "T15 citations resolve: labels match targets, N.M rules exist, no old scheme" \
               || bad "T15 citations" "$errs"

# --- 16. The artifacts AGENTS.md forbids by name are absent ---------------
# Every other case asserts that a file we know about is well-formed. None asserted
# that a forbidden file is ABSENT, so on 2026-09-11 an agent commissioned to audit
# this repo created sessions.txt - named in AGENTS.md's Negative Constraints, and
# in handover.md twice more - and the suite passed. Backlog B64.
# Deliberately only the three artifacts AGENTS.md already names. A denylist grows
# one row per incident and never shrinks; this one tracks that sentence, nothing
# more. If AGENTS.md stops naming one, delete it here too.
# Three tiers, because "this file exists" covers three different situations.
#   TRACKED              - apparatus entered the repo. What AGENTS.md forbids. Hard fail.
#   untracked, NOT ignored - one `git add -A` from being committed by accident. Warn.
#   untracked and IGNORED  - deliberately excluded, which is the correct handling. Silent.
# The third tier exists because the HLM plugin appends sessions.txt to every git project it
# runs in, as a local lookup aid. That is a tool doing its job, and a guard that fires on the
# correct handling of it is noise - which is how a suite teaches people to ignore its output.
# A copy with no git (a tarball, a plain directory copy) cannot tell tracked from not: there a
# forbidden file is part of what was shipped, so it fails as tracked (cold read, 2026-10-26).
errs=""; warns=""
in_git=0; git rev-parse --is-inside-work-tree >/dev/null 2>&1 && in_git=1
for forbidden in sessions.txt ta docs/context-index.md; do
  [ -e "$forbidden" ] || continue
  if [ "$in_git" -eq 0 ]; then
    errs="$errs\n    $forbidden is present in a tree with no git - a copy that ships it"
  elif git ls-files --error-unmatch "$forbidden" >/dev/null 2>&1; then
    errs="$errs\n    $forbidden is TRACKED - AGENTS.md Negative Constraints forbids it by name"
  elif ! git check-ignore -q "$forbidden" 2>/dev/null; then
    warns="$warns\n    $forbidden is present and not ignored - gitignore it or delete it, do not commit it"
  fi
done
if [ -n "$errs" ]; then bad "T16 forbidden artifact committed" "$errs"
else
  ok "T16 Tier 3 apparatus AGENTS.md declines is not in the repo"
  [ -n "$warns" ] && printf '  \033[33mWARN\033[0m  untracked artifact in the working dir:%b\n' "$warns"
fi

# --- 17. SKILL.md names none of this repo's own development files ----------
# SKILL.md is loaded into every project the skill runs in. Its closing section described this
# repo's backlog.md and designs/; in the first behavioural batch (full-1, 2026-10-15) agents
# with SKILL.md preloaded built a backlog.md in a 9-file project, 2 runs of 5, and neither had
# opened a skill file. Maintainer pointers belong in AGENTS.md, which only this repo loads.
# The concepts (a backlog, a handover) are fine; the paths are what read as "make this here".
# references/27-handover.md is a shipped file, not this repo's handover.md: drop those paths first.
dev="$(sed -E 's#references/[A-Za-z0-9._-]+##g' SKILL.md | grep -nE 'backlog\.md|handover\.md|designs/|tests/test-plan\.md|eval/|SECOND-OPINION' || true)"
if [ -n "$dev" ]; then bad "T17 SKILL.md names a development-only file" "\n$(echo "$dev" | sed 's/^/    /')"
else ok "T17 SKILL.md names no development-only file"; fi

# --- 18. The delegation instruction ships in the root template --------------
# 28.5 measured a sentence in the standing instructions, not the rule: the rule is read when an
# agent opens 19, the template's line is loaded before every brief. Both halves must stay.
errs=""
says config/AGENTS.root.template.md 'defects you find while investigating go into the brief to be fixed, unless fixing them is risky; then say why you left them (28.5)' \
  || errs="$errs\n    config/AGENTS.root.template.md: no delegation line (28.5), or it is reworded"
rule_says references/28-delegating.md 28.5 'AGENTS.root.template.md' \
  || errs="$errs\n    references/28-delegating.md: 28.5 missing or not pointing at the template"
[ -z "$errs" ] && ok "T18 the delegation instruction ships in the root template" || bad "T18 delegation instruction" "$errs"

# --- 19. A commit carries what the diff cannot show --------------------------
# 25.10 is test 42's finding: a fresh session kept a first session's work when its commits named
# the operator's fact, and undid it when the work sat uncommitted. 15.1 must route a reason to the
# commit message where there is no decision log, or the two rules disagree on a small project.
errs=""
grep -q '^### 25\.10 Commit each finished step, with what the diff cannot show' references/25-shipping.md \
  && rule_says references/25-shipping.md 25.10 'the message carries what it cannot' \
  || errs="$errs\n    references/25-shipping.md: 25.10 missing or not naming what the diff cannot show"
rule_says references/15-running-tests.md 15.1 'or the commit message where there is none ([25.10](25-shipping.md))' \
  || errs="$errs\n    references/15-running-tests.md: 15.1 routes a reason only to a decision log"
says SKILL.md 'Commit each step once it works, before the next, with what the diff cannot show: a fresh session or a compaction starts from `git log` ([25.10](references/25-shipping.md)).' \
  || errs="$errs\n    SKILL.md: no 25.10 line (eval test 52: with the line, OpenCode committed per item in 3 of 8 runs against 0 of 24)"
[ -z "$errs" ] && ok "T19 a commit carries what the diff cannot show" || bad "T19 commit reasons" "$errs"

# --- 20. The verifier instruction ships in the root template ------------------
# 28.6's verifier was measured in eval test 44, its template line in test 45: both halves must stay.
errs=""
says config/AGENTS.root.template.md "have a second worker verify it against the task: it runs the tests, reads the diff and treats the developer's report as claims (28.6)" \
  || errs="$errs\n    config/AGENTS.root.template.md: no verifier line (28.6), or it is reworded"
rule_says references/28-delegating.md 28.6 'beside 28.5' \
  || errs="$errs\n    references/28-delegating.md: 28.6 missing or not pointing at the template"
[ -z "$errs" ] && ok "T20 the verifier instruction ships in the root template" || bad "T20 verifier instruction" "$errs"

# --- 21. 28.6 states what a verifier cannot find -------------------------------
# Eval test 46: checked against the task, hand-offs nobody read fixed the neighbouring defect in
# 1 of 24. Without the limit, 28.6 reads as if the verifier covers what not reading misses.
errs=""
rule_says references/28-delegating.md 28.6 'cannot find a defect nobody asked about' \
  || errs="$errs\n    references/28-delegating.md: 28.6 does not say a verifier cannot find what nobody asked about"
rule_says references/28-delegating.md 28.6 'before you brief (28.5), or say in your report that the check stopped at the task' \
  || errs="$errs\n    references/28-delegating.md: 28.6 does not route the neighbouring defect to 28.5, or drops the report's limit"
[ -z "$errs" ] && ok "T21 28.6 states what a verifier cannot find" || bad "T21 verifier limit" "$errs"

# --- 22. An atomic save keeps the file's mode ----------------------------------
# Eval tests 44 and 49: mkstemp + rename left the live data file at 0600 with every test green.
errs=""
grep -q '^### 11\.10 Replacing a file keeps its mode' references/11-resilient-code.md \
  || errs="$errs\n    references/11-resilient-code.md: no 11.10"
rule_says references/11-resilient-code.md 11.10 "Copy the original's mode onto the temp file before the rename (\`shutil.copymode(path, tmp)\`" \
  || errs="$errs\n    references/11-resilient-code.md: 11.10 does not name the fix"
grep -q "copies the original file's mode onto the temp file before the rename.*(11\.10)" references/11-resilient-code.md \
  || errs="$errs\n    references/11-resilient-code.md: no Rules line for 11.10"
says SKILL.md "copies the original's mode onto the temp file first: \`mkstemp\` creates it 0600 ([11.10](references/11-resilient-code.md))." \
  || errs="$errs\n    SKILL.md: no 11.10 line (eval test 50: OpenCode reads no numbered file)"
[ -z "$errs" ] && ok "T22 an atomic save keeps the file's mode (11.10)" || bad "T22 atomic save mode" "$errs"

# --- 23. The root template says to load the skill ------------------------------
# Eval tests 53-55: beside 18 other skills OpenCode loaded this one in 4 of 8 runs, Hermes in 0 of
# 16 with or without them; the template's line took OpenCode, Pi and Hermes to 8 of 8. Both halves must stay.
errs=""
says config/AGENTS.root.template.md 'Load the `coding-strategy` skill before the first edit of a session, and read the file its `SKILL.md` routes you to for the task (5.9)' \
  || errs="$errs\n    config/AGENTS.root.template.md: no line saying to load the skill (5.9)"
rule_says references/05-context-docs.md 5.9 'AGENTS.root.template.md' \
  || errs="$errs\n    references/05-context-docs.md: 5.9 missing or not pointing at the template"
grep -q 'says to load the `coding-strategy` skill before the first edit (5\.9)' references/05-context-docs.md \
  || errs="$errs\n    references/05-context-docs.md: no Rules line for 5.9"
grep -E '^\| `AGENTS\.root\.template\.md`' config/README.md | grep '\[5\.9\]' >/dev/null \
  || errs="$errs\n    config/README.md: the root template's row does not cite 5.9"
[ -z "$errs" ] && ok "T23 the root template says to load the skill (5.9)" || bad "T23 load the skill" "$errs"

# --- 24. The secret hook scans what is staged ---------------------------------------
# Round 15: on gitleaks 8.19.2 `git --staged` scans history and passes a staged secret with exit 0;
# `protect --staged` caught it on 8.18.4 through 8.30.1. `--help` exits 0 for any word, so the
# probe must read the help text. The first spelling tried must be protect.
errs=""
h=config/pre-commit-secret-scan.sh
grep -qF "gitleaks protect --help 2>&1 | grep -- '--staged' >/dev/null" "$h" \
  || errs="$errs\n    $h: the spelling probe does not read protect's help text"
[ "$(grep -m1 -oE '_gl=\(gitleaks [a-z]+' "$h")" = "_gl=(gitleaks protect" ] \
  || errs="$errs\n    $h: \`git --staged\` is tried before \`protect --staged\` (8.19.2 scans history)"
grep -qF -- 'gl_out="$("${_gl[@]}"' "$h" \
  || errs="$errs\n    $h: the scan does not run the selected spelling (\${_gl[@]})"
[ -z "$errs" ] && ok "T24 the secret hook scans what is staged" || bad "T24 staged scan" "$errs"

# --- 25. One fence and heading dialect -------------------------------------------
# The extractors (T4, T5, rule_body) read fences as column-one backticks and headings as column-one
# hashes. A renderer also reads `~~~`, indented fences and headings indented up to three spaces, and
# one unclosed fence hid six rules from T4 with the suite green (round 17). So the tree is held to
# the dialect the extractors speak: column-one backtick fences, an even number per file, no tilde
# fences, nothing indented one to three spaces before a fence or a heading.
errs=""
for f in $(find $LIVE -name '*.md'); do
  n="$(grep -c '^```' "$f")"
  [ $((n % 2)) -eq 0 ] || errs="$errs\n    $f: $n fence lines, one is unclosed"
  odd="$(grep -nE '^~~~|^ {1,3}(```|~~~|#{1,6} )' "$f" | head -n 3)"
  [ -z "$odd" ] || errs="$errs\n    $f: a fence or heading the extractors cannot read: $odd"
done
[ -z "$errs" ] && ok "T25 fences and headings are in the dialect the extractors read" || bad "T25 fence dialect" "$errs"

# --- 26. Every shipped file says what it is for ---------------------------------
# A reader met safe-delete.sh with no idea why it was there (2026-10-26): the headers said how it
# worked and which rule it enforced, not what problem it solves. So each copy target in config/
# and each script in tests/ has its own section in its folder's README, and each script's header
# says why in a line and points there. Listed from disk, so a new file needs its section.
errs=""
for f in config/* tests/*.sh; do
  [ -f "$f" ] || continue   # a __pycache__ left by an import is not a shipped file
  b="$(basename "$f")"; d="$(dirname "$f")"
  case "$b" in README.md|test-plan.md) continue ;; esac
  grep -qF "### \`$b\`" "$d/README.md" 2>/dev/null || errs="$errs\n    $d/README.md has no section for $b"
  case "$b" in
    *.sh|*.py) grep -q "^# Why: \|^Why: " "$f" && grep -qF "More: $d/README.md" "$f" \
                 || errs="$errs\n    $f: no 'Why:' line pointing to $d/README.md in its header" ;;
  esac
done
[ -z "$errs" ] && ok "T26 every shipped file has a README section, every script a why line" || bad "T26 unexplained shipped file" "$errs"

# --- 27. SKILL.md sends an irreversible delete through a guard -------------------------
# The guards were named in SKILL.md only as copy targets, which an agent reads as setup material,
# not as what to reach for before a delete (2026-10-26). Lines in SKILL.md's opening reach agents
# that read nothing else (tests 51, 52, 57), so the instruction lives there, citing 24.5.
errs=""
says SKILL.md 'A delete you cannot undo (rows a sync removes, files on a computed path) goes through a guard' \
  || errs="$errs\n    SKILL.md: the opening no longer sends an irreversible delete through a guard"
says SKILL.md 'if a guard refuses, stop and report why ([24.5](references/24-quality-gates.md))' \
  || errs="$errs\n    SKILL.md: the delete line no longer says to stop on a refusal, citing 24.5"
rule_says references/24-quality-gates.md 24.5 'delete-guard-hook.py' \
  || errs="$errs\n    24.5 no longer names the tool-layer hook"
[ -z "$errs" ] && ok "T27 SKILL.md sends a delete you cannot undo through a guard (24.5)" || bad "T27 delete guard line" "$errs"

# --- 28. Condensing a handover keeps what is recorded nowhere else ----------------------------
# 27.6 said only to delete what no longer holds, the commits keeping the history; trimming this
# repo's handover found four facts no commit or record held (2026-10-27). The rule now sends that
# detail to handover-details.md, word for word, and says to check before cutting.
errs=""
rule_says references/27-handover.md 27.6 'into `handover-details.md`, linked from the entry' \
  || errs="$errs\n    27.6 no longer moves unrecorded detail to handover-details.md, linked"
rule_says references/27-handover.md 27.6 'Grep each fact where it is said to live before' \
  || errs="$errs\n    27.6 no longer says to check a fact is recorded before cutting it"
[ -z "$errs" ] && ok "T28 a condensed handover keeps unrecorded detail in handover-details.md (27.6)" || bad "T28 handover condensing" "$errs"

# --- 29. A tier's list is a ceiling, not a work order --------------------------------------
# File 01 said to work down the tier's list, and 1.6's cost test covered only what lay beyond it
# (cold read F19). Agents cite the ceiling for what they skip (eval test 60), so keep it said.
errs=""
says references/01-sizing-to-the-project.md 'Its list is a ceiling, not a work order' \
  || errs="$errs\n    01: the intro no longer calls the tier's list a ceiling"
rule_says references/01-sizing-to-the-project.md 1.6 'It applies inside your tier' \
  || errs="$errs\n    1.6 no longer applies inside the tier's list"
[ -z "$errs" ] && ok "T29 a tier's list is a ceiling, and 1.6 applies inside it" || bad "T29 tier ceiling" "$errs"

if [ "${1:-}" = "--self-test" ]; then
  # B20 applied to this suite: a guard is not evidence until it has been seen to fail.
  # The controls were each run once when their case was written; bugs 14, 17 and 18 are
  # what that costs - two enums silently stopped matching, and one of them still said PASS.
  echo; echo "--- self-test: each guard must FAIL on a seeded break ---"
  st_fail=0
  # swap FILE OLD NEW: replace a literal string once, failing if it is absent, so a probe
  # whose target moved is a setup failure rather than a silent no-op.
  swap() { python3 - "$@" <<'PY2'
import sys
p, a, b = sys.argv[1:4]
s = open(p).read()
if s.count(a) != 1: sys.exit(1)
open(p, "w").write(s.replace(a, b))
PY2
  }
  # move_pointer FILE FROM TO TEXT: take TEXT out of rule FROM and put it at the end of rule TO.
  move_pointer() { python3 - "$@" <<'PY2'
import re, sys
p, frm, to, text = sys.argv[1:5]
s = open(p).read()
def span(n):
    m = re.search(r"^### " + re.escape(n) + r" .*$", s, re.M)
    e = re.search(r"^### ", s[m.end():], re.M)
    return m.end(), m.end() + e.start() if e else len(s)
a, b = span(frm)
if text not in s[a:b]: sys.exit(1)
s = s[:a] + s[a:b].replace(text, "") + s[b:]
a, b = span(to)
s = s[:b] + text + "\n\n" + s[b:]
open(p, "w").write(s)
PY2
  }
  probe() { # name, setup-command
    # A setup that fails must not count as the guard firing: the subshell's non-zero exit
    # used to read as "fails when broken", so a mistyped probe passed while testing nothing.
    d="$(mktemp -d)/r"; cp -r . "$d" 2>/dev/null
    # A copy with no .git still has probes that `git add`: give it a repo, as a checkout has.
    [ -e "$d/.git" ] || ( cd "$d" && git init -q && git add -A ) >/dev/null 2>&1
    if ! ( cd "$d" && eval "$2" ) >/dev/null 2>&1; then
      printf '  \033[31mBAD\033[0m   %s probe setup failed - the guard was not exercised\n' "$1"; st_fail=$((st_fail+1))
    elif ( cd "$d" && bash tests/check-docs.sh >/dev/null 2>&1 ); then
      printf '  \033[31mBAD\033[0m   %s still PASSES when broken\n' "$1"; st_fail=$((st_fail+1))
    else printf '  \033[32mOK\033[0m    %s fails when broken\n' "$1"; fi
    rm -rf "$(dirname "$d")"
  }
  probe "T1  link"        "echo '[x](references/nope.md)' >> SKILL.md"
  probe "T2  routing"     "sed -i '/references\/20-debugging.md/d' SKILL.md"
  probe "T3  opening"     "sed -i 's/^  Plan, test, review, commit, set up repos, run unattended\\./  Plan, test, review, commit, set up repos, run unattended work overnight./' SKILL.md"
  probe "T4  file gap"    "mv references/37-reference.md references/38-reference.md"
  probe "T4  rule gap"    "sed -i 's/^### 20\.3 /### 20.4 /' references/20-debugging.md"
  probe "T5  H1"          "sed -i '1s/.*/# Nope/' references/37-reference.md"
  probe "T5  rules cite"  "sed -i 's/(20\.3)$/(20.99)/' references/20-debugging.md && tests/build-cards.sh"
  probe "T5  fenced rule" "sed -i 's/(20\.3)$/(20.99)/' references/20-debugging.md && printf '\\n\`\`\`\\n### 20.99 x\\n\`\`\`\\n' >> references/20-debugging.md && tests/build-cards.sh"
  probe "T5  rules late"  "python3 -c \"import re;p='references/20-debugging.md';s=open(p).read();b=re.search(r'\\*\\*Rules\\*\\*\\n\\n(?:- .*\\n)+\\n',s).group(0);s=s.replace(b,'');i=s.index('### 20.2 ');open(p,'w').write(s[:i]+b+s[i:])\" && tests/build-cards.sh"
  probe "T9  TODO"        "printf 'TODO: x\\n' >> AGENTS.md"
  probe "T10 mechanism"   "sed -i 's/return False, f\"authority is empty/return True, f\"authority is empty/' config/guard-shrink.py"
  probe "T10 shell"       "printf 'if then fi(\\n' >> config/pre-commit-secret-scan.sh"
  probe "T11 size"        "python3 -c \"open('references/37-reference.md','a').write('x'*8000)\""
  probe "T12 stale card"  "sed -i 's/(20\.3)$/(20.3) edited/' references/20-debugging.md"
  probe "T14 status"      "printf '\\n### B999 - probe\\n\\nno status line\\n' >> backlog.md"
  probe "T14 date"        "printf '\\n### B999 - probe\\n\\n**Status:** declined\\n**Declined:** someday\\n' >> backlog.md"
  probe "T15 label"       "printf '\\nSee [9](16-checking-what-you-claim.md) here.\\n' >> README.md"
  probe "T15 config"      "sed -i 's/(25\\.6)/(25.99)/' config/pre-push-verify.sh"
  probe "T15 config prose" "sed -i 's/Per 4\\.4 the/Per 4.99 the/' config/pre-push-verify.sh"
  probe "T15 config py"   "sed -i 's/Rule 13\\.2:/Rule 13.99:/' config/guard-shrink.py"
  probe "T10 named"       "sed -i 's/--self-test/--selftest/g' config/safe-delete.sh"
  probe "T15 config zero" "sed -i 's/(25\\.6)/(06.99)/' config/pre-push-verify.sh"
  probe "T15 config new"  "printf '# per Rule 13.99\\n' > config/sync-guard.yaml"
  probe "T15 config pair" "sed -i 's/(25\\.6)/(25.6,25.99)/' config/pre-push-verify.sh"
  probe "T15 config dots" "sed -i 's/(25\\.6)/(25.99...)/' config/pre-push-verify.sh"
  # T13's seed shrinks the files rather than growing the cards: cards grow only through Rules
  # lines, which trips T12 (card differs) or, rebuilt, T11 (the size limit). Keep every heading
  # and the Rules block, drop the rule bodies (round twelve; rounds ten and eleven had it unwritable).
  probe "T13 ratio"       "for f in references/[0-9][0-9]-*.md; do case \$f in *rules-card*) ;; *) awk 'BEGIN{h=1} /^### [0-9]+\.[0-9]+/{h=0} h||/^#{1,3} [0-9]/{print}' \"\$f\" > \"\$f.t\" && mv \"\$f.t\" \"\$f\" ;; esac; done"
  probe "T15 rule"        "printf '\\nSee [14.99](14-writing-tests.md) here.\\n' >> references/37-reference.md"
  probe "T15 old scheme"  "printf '\\nSee phase-3b here.\\n' >> operator-guide.md"
  probe "T15 space form"  "printf '\\nSee phase 9 here.\\n' >> references/37-reference.md"
  probe "T15 asset"       "printf '\\n# see phase 14.99\\n' >> config/env.example"
  probe "T15 asset .."    "printf '\\n# Rule 6..99\\n' >> config/env.example"
  probe "T15 label .."    "printf '\\nsee [6..99](references/25-shipping.md)\\n' >> operator-guide.md"
  probe "T16 sessions"    "touch sessions.txt && git add -f sessions.txt"
  probe "T16 ta/"         "mkdir -p ta && touch ta/x && git add -f ta/x"
  probe "T16 index"       "mkdir -p docs && touch docs/context-index.md && git add -f docs/context-index.md"
  probe "T17 dev file"    "echo 'Read backlog.md first.' >> SKILL.md"
  probe "T17 designs/"    "echo 'Ideas go in designs/x.md.' >> SKILL.md"
  probe "T18 template"    "sed -i '/defects you find while investigating/d' config/AGENTS.root.template.md"
  probe "T19 rule"        "sed -i 's/^### 25\\.10 /### 25.10x /' references/25-shipping.md"
  probe "T19 SKILL line"  "sed -i '/Commit each step once it works, before the next/d' SKILL.md"
  probe "T19 15.1 route"  "sed -i 's/commit message where there is none/commit message/' references/15-running-tests.md"
  probe "T20 template"    "sed -i '/have a second worker verify it against the task/d' config/AGENTS.root.template.md"
  probe "T20 rule"        "sed -i 's/^### 28\\.6 /### 28.6x /' references/28-delegating.md"
  probe "T21 limit"       "sed -i 's/cannot find a defect nobody asked about/finds what the developer missed/' references/28-delegating.md"
  probe "T21 route"       "sed -i 's/before you brief (28\\.5)/before you brief/' references/28-delegating.md"
  probe "T22 rule"        "sed -i 's/^### 11\\.10 /### 11.10x /' references/11-resilient-code.md"
  probe "T22 fix"         "sed -i 's/shutil.copymode(path, tmp)/shutil.copymode/' references/11-resilient-code.md"
  probe "T22 SKILL line"  "sed -i \"/copies the original's mode onto the temp/d\" SKILL.md"
  probe "T22 card line"   "sed -i \"/copies the original file's mode onto the temp file/d\" references/11-resilient-code.md"
  probe "T23 template"    "sed -i '/Load the .coding-strategy. skill before the first edit/d' config/AGENTS.root.template.md"
  probe "T23 rule"        "sed -i 's/^### 5\\.9 /### 5.9x /' references/05-context-docs.md"
  probe "T23 card line"   "sed -i '/before the first edit (5\\.9)/d' references/05-context-docs.md"
  probe "T23 config row"  "sed -i 's/, is \\[5\\.9\\]([^)]*)//' config/README.md"
  probe "T24 probe"       "sed -i \"s/gitleaks protect --help 2>&1 | grep -- '--staged' >\\/dev\\/null/gitleaks git --help >\\/dev\\/null 2>\\&1/\" config/pre-commit-secret-scan.sh"
  probe "T24 order"       "python3 -c \"import re;p='config/pre-commit-secret-scan.sh';s=open(p).read();a='_gl=(gitleaks protect';b='_gl=(gitleaks git';s=s.replace(a,'@@').replace(b,a).replace('@@',b);open(p,'w').write(s)\""
  probe "T24 call site"   "swap config/pre-commit-secret-scan.sh '\"\${_gl[@]}\"' 'gitleaks git --staged --redact --verbose'"
  probe "T18 pointer"     "move_pointer references/28-delegating.md 28.5 28.2 AGENTS.root.template.md"
  probe "T20 pointer"     "move_pointer references/28-delegating.md 28.6 28.2 'beside 28.5'"
  probe "T23 pointer"     "move_pointer references/05-context-docs.md 5.9 5.2 AGENTS.root.template.md"
  probe "T10 root note"   "swap config/safe-delete.sh 'I/O-failure cases did not run; run as a normal user' ''"
  probe "T23 paragraph"   "swap config/AGENTS.root.template.md 'before the first edit of a session, and read' \$'before the first edit of a session,\\n\\nand read'"
  # Round 17: the same moves for T19, T21 and T22; a fenced example standing in for the prose
  # pointer; a blank line holding spaces.
  probe "T19 moved"       "move_pointer references/25-shipping.md 25.10 25.9 'the message carries what it cannot'"
  probe "T19 15.1 moved"  "move_pointer references/15-running-tests.md 15.1 15.2 'commit message where there is none'"
  probe "T21 moved"       "move_pointer references/28-delegating.md 28.6 28.4 'cannot find a defect nobody asked about'"
  probe "T22 moved"       "move_pointer references/11-resilient-code.md 11.10 11.9 \"Copy the original's mode onto the temp file before the rename\""
  probe "T18 fenced"      "swap references/28-delegating.md '\`config/AGENTS.root.template.md\`, under Work Guidance' 'the root template, under Work Guidance' && swap references/28-delegating.md '### 28.6 ' \$'\`\`\`\\nconfig/AGENTS.root.template.md\\n\`\`\`\\n\\n### 28.6 '"
  probe "T23 space line"  "swap config/AGENTS.root.template.md 'before the first edit of a session, and read' \$'before the first edit of a session,\\n   \\nand read'"
  probe "T22 under ##"    "swap references/11-resilient-code.md \"Copy the original's mode onto the temp file before the rename\" 'Keep the mode' && printf '\\n## Notes\\n\\nCopy the original'\\''s mode onto the temp file before the rename (\`shutil.copymode(path, tmp)\`.\\n' >> references/11-resilient-code.md"
  probe "T25 unclosed"    "swap references/19-instrumentation.md '### 19.2 ' \$'\`\`\`\\n\\n### 19.2 '"
  probe "T25 tilde"       "printf '\\n~~~\\nx\\n~~~\\n' >> references/28-delegating.md"
  probe "T25 indented"    "printf '\\n  ### 28.99 Indented\\n' >> references/28-delegating.md"
  # Round 15's rewordings: each kept the old anchor and inverted or dropped the instruction.
  probe "T18 reworded"    "sed -i 's/go into the brief to be fixed/go into the brief to be filed/' config/AGENTS.root.template.md"
  probe "T19 reworded"    "sed -i 's/with what the diff cannot show:/with a clear message:/' SKILL.md"
  probe "T20 reworded"    "sed -i \"s/treats the developer's report as claims/treats the developer's report as the source of truth/\" config/AGENTS.root.template.md"
  probe "T21 reworded"    "sed -i 's/, or say in your report that the check stopped at the task/; a green suite covers the rest/' references/28-delegating.md"
  probe "T22 reworded"    "sed -i 's/onto the temp file before the rename/onto the temp file after the rename/' references/11-resilient-code.md && tests/build-cards.sh >/dev/null"
  probe "T23 reworded"    "sed -i 's/, and read the file its .SKILL.md. routes you to for the task//' config/AGENTS.root.template.md"
  probe "T26 section"     "sed -i 's/^### .safe-delete.sh.$/### safe-delete/' config/README.md"
  probe "T26 new file"    "cp config/env.example config/new.example"
  probe "T26 why line"    "sed -i '/^# Why: a delete on a path/d' config/safe-delete.sh"
  probe "T26 tests"       "sed -i 's/^### .build-cards.sh.$/### build-cards/' tests/README.md"
  probe "T27 line"        "sed -i '/^A delete you cannot undo/d' SKILL.md"
  probe "T27 stop"        "sed -i 's/if a guard refuses, stop and report why/if a guard refuses, try again/' SKILL.md"
  probe "T27 hook"        "sed -i 's/and \\[.delete-guard-hook.py.\\]([^)]*) for the agent.s tool/and a hook for the agent\x27s tool/' references/24-quality-gates.md"
  probe "T28 move"        "sed -i 's/into .handover-details.md., linked from the entry/into a notes file/' references/27-handover.md"
  probe "T28 grep"        "sed -i 's/^cutting it: one trim/cutting it - one trim/; s/Grep each fact where it is said to live before/Read the entry once before/' references/27-handover.md"
  probe "T29 intro"       "sed -i 's/Its list is a ceiling, not a work order/Work down its list/' references/01-sizing-to-the-project.md"
  probe "T29 inside"      "sed -i 's/It applies inside your tier.s list as/It applies beyond your tier.s list as/' references/01-sizing-to-the-project.md"
  echo
  [ "$st_fail" -eq 0 ] && echo "self-test: all guards bite" || echo "self-test: $st_fail guard(s) did not fire"
  exit $([ "$st_fail" -eq 0 ] && echo 0 || echo 1)
fi

echo
printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
