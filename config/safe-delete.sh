#!/usr/bin/env bash
# safe-delete - the destructive step, made refusable and reversible.
#
# Why: a delete on a path your code computed (from config, an ID, a model) is one empty variable
# or one stray symlink away from deleting the wrong tree, and rm cannot be undone. Make this the
# project's one way to delete files: it deletes only under roots you mark, dry-runs unless told
# otherwise, and moves to a trash directory instead of deleting. More: config/README.md.
#
#   safe-delete.sh PATH...        dry run: prints what it would move
#   ALLOW_DESTRUCTIVE=1 safe-delete.sh PATH...
#   safe-delete.sh --self-test
#
# Rules 12.3, 11.7 and 31.2 as a mechanism: a delete on a computed path resolves symlinks first and
# refuses unless the result is strictly below an allowlisted root (never the root itself) that
# carries a marker file; nothing moves without an explicit grant (ALLOW_DESTRUCTIVE=1); and what
# does move goes to its own dated trash directory under its root, not to rm - so an accepted
# mistake can still be put back. Both the named path and what it resolves to must be below the
# root; the named one moves, so a symlink moves as a link and its target stays. Prose alone did not hold rules like these for a weaker model (the skill's agent
# trials); put this on the path the deletion takes.
#
# Configuration:
#   SAFE_DELETE_ROOTS   colon-separated allowlisted roots (required; no default, by design)
#   SAFE_DELETE_MARKER  file that must exist in a root to mark it managed (default .safe-delete-root)
#   ALLOW_DESTRUCTIVE   1 to act; anything else is a dry run
# The first two come from the environment if set there (even empty), else from the project's
# .env, else from its .safe-delete.conf - the project being the git checkout this script sits in.
# Those files are read as KEY=VALUE text, never sourced, and only for these two keys; a relative
# root in them is relative to the project, so one value works on every host. ALLOW_DESTRUCTIVE is
# read from the environment only: no file can turn a dry run into a move.
#
# Exit: 0 done or dry-run, 3 refused, 2 usage.
set -uo pipefail

refuse() { echo "REFUSED: $*" >&2; exit 3; }

PROJECT="$(git -C "$(dirname -- "$(realpath -- "$0")")" rev-parse --show-toplevel 2>/dev/null)"
conf() {  # KEY: set CONF_VALUE and CONF_FROM from the first project file that sets KEY
  local f line
  CONF_VALUE=""; CONF_FROM=""
  [ -n "$PROJECT" ] || return 1
  for f in "$PROJECT/.env" "$PROJECT/.safe-delete.conf"; do
    [ -f "$f" ] || continue
    line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?$1=" "$f" | tail -n 1)"
    [ -n "$line" ] || continue
    CONF_VALUE="${line#*=}"; CONF_VALUE="${CONF_VALUE%$'\r'}"
    if [[ "$CONF_VALUE" == \"*\" || "$CONF_VALUE" == \'*\' ]]; then CONF_VALUE="${CONF_VALUE:1:${#CONF_VALUE}-2}"; fi
    CONF_FROM="$f"; return 0
  done
  return 1
}
if [ -n "${SAFE_DELETE_ROOTS+set}" ]; then ROOTS="$SAFE_DELETE_ROOTS"; ROOTS_FROM="the environment"
elif conf SAFE_DELETE_ROOTS; then
  ROOTS=""; ROOTS_FROM="$CONF_FROM"
  IFS=: read -r -a _roots <<< "$CONF_VALUE"
  for _r in "${_roots[@]}"; do
    case "$_r" in ""|/*) ;; *) _r="$PROJECT/$_r" ;; esac
    ROOTS="${ROOTS:+$ROOTS:}$_r"
  done
else ROOTS=""; ROOTS_FROM="nowhere: set SAFE_DELETE_ROOTS in the environment, .env or .safe-delete.conf"
fi
if [ -n "${SAFE_DELETE_MARKER+set}" ]; then MARKER="$SAFE_DELETE_MARKER"
elif conf SAFE_DELETE_MARKER; then MARKER="$CONF_VALUE"
else MARKER=".safe-delete-root"; fi
MARKER="${MARKER:-.safe-delete-root}"

marked_roots() {  # each allowlisted root that exists and carries the marker, resolved
  local r
  IFS=: read -r -a roots <<< "$ROOTS"
  for r in "${roots[@]}"; do
    [ -n "$r" ] || continue
    r="$(realpath -e -- "$r" 2>/dev/null)" || continue
    [ -f "$r/$MARKER" ] && echo "$r"
  done
}

root_for() {  # print the deepest marked root strictly above $1, or nothing
  local target="$1" r best=""
  while IFS= read -r r; do
    case "$target" in "$r"/?*) [ "${#r}" -gt "${#best}" ] && best="$r" ;; esac
  done < <(marked_roots)
  [ -n "$best" ] && echo "$best"
}

delete_one() {
  local arg="$1" target named name root rel slot dest
  [ -n "$arg" ] || refuse "empty path"  # an empty variable must never widen into a default
  name="$(basename -- "$arg")"
  case "$name" in .|..|/) refuse "$arg does not name an entry" ;; esac
  # The named path is what moves: its parent resolved, its own name kept, so a link stays a link.
  # What it resolves to is checked too, so a link out of the root is still refused (12.3).
  named="$(realpath -e -- "$(dirname -- "$arg")" 2>/dev/null)/$name" || refuse "$arg: its directory does not exist"
  [ -e "$named" ] || [ -L "$named" ] || refuse "$arg does not exist"
  target="$(realpath -e -- "$arg" 2>/dev/null)" || refuse "$arg does not resolve"
  root="$(root_for "$named")"
  [ -n "$root" ] && [ "$(root_for "$target")" = "$root" ] \
    || refuse "$named is not strictly below an allowlisted root marked with $MARKER (roots '$ROOTS', from $ROOTS_FROM)"
  # Every listed root, not only the one chosen: with one root inside another, the inner root, its
  # trash and its marker are all strictly below the outer one (found in review).
  local r
  while IFS= read -r r; do
    [ "$named" = "$r" ] && refuse "$named is an allowlisted root"
    case "$named" in "$r/.trash"|"$r/.trash/"*) refuse "$named is already in the trash" ;; esac
    [ "$named" = "$r/$MARKER" ] && refuse "$named is a root's marker"
    case "$r" in "$named"/*) refuse "$named contains the allowlisted root $r" ;; esac
  done < <(marked_roots)
  [ "${CHECK_ONLY:-}" = "1" ] && { echo "$named"; return 0; }
  rel="${named#"$root"/}"
  if [ "${ALLOW_DESTRUCTIVE:-}" != "1" ]; then
    echo "dry run: would move $named -> $root/.trash/$(date +%Y%m%d-%H%M%S).*/$rel (set ALLOW_DESTRUCTIVE=1 to act)"
    return 0
  fi
  # One slot per call: two deletes of one path in the same second used to share a slot, and the
  # second mv overwrote the first copy (found in review, 2026-10-20).
  mkdir -p -- "$root/.trash" && slot="$(mktemp -d -- "$root/.trash/$(date +%Y%m%d-%H%M%S).XXXX")" \
    || refuse "could not make a trash slot under $root/.trash"
  dest="$slot/$rel"
  mkdir -p -- "$(dirname -- "$dest")" && mv -n -- "$named" "$dest" && [ ! -e "$named" ] && [ ! -L "$named" ] \
    || refuse "could not move $named"
  echo "moved $named -> $dest   (undo: mv '$dest' '$named')"
}

self_test() {
  local d fails=0 self
  self="$(realpath -- "$0")"  # run as `bash safe-delete.sh` from its own directory, $0 has no slash
  d="$(mktemp -d)"; trap 'rm -rf "$d"' RETURN
  mkdir -p "$d/root/data" "$d/root/releases/v3" "$d/root-old" "$d/root/.trash/t" "$d/outside"
  touch "$d/root/$MARKER" "$d/root/data/x" "$d/root/releases/v3/app" "$d/root-old/z" "$d/root/.trash/t/w" "$d/outside/y"
  ln -s "$d/outside/y" "$d/root/link"
  ln -s releases/v3 "$d/root/current"
  expect() {  # name, want-exit, command... ; the script itself is run as: bash "$self"
    local name="$1" want="$2"; shift 2
    ( "$@" ) >/dev/null 2>&1; local got=$?
    if [ "$got" = "$want" ]; then echo "  ok   $name"; else echo "  FAIL $name (exit $got, want $want)"; fails=$((fails+1)); fi
  }
  # A refusal checked by exit code alone hides a removed check that a later one backs up with the
  # same exit 3, so these also name the refusal that must fire (found in review).
  refuses() {  # name, message fragment, command...
    local name="$1" says="$2" out; shift 2
    out="$( ( "$@" ) 2>&1 )"; local got=$?
    if [ "$got" = 3 ] && [[ "$out" == *"$says"* ]]; then echo "  ok   $name"
    else echo "  FAIL $name (exit $got, want 3 saying '$says')"; fails=$((fails+1)); fi
  }
  export SAFE_DELETE_ROOTS="$d/root"
  expect "outside the root is refused"        3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/outside/y"
  expect "the root itself is refused"         3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root"
  expect "a symlink out of the root refused"  3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/link"
  refuses "an empty path is refused"          "empty path" env ALLOW_DESTRUCTIVE=1 bash "$self" ""
  refuses "a dot is refused"                  "does not name an entry" env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/."
  refuses "a missing path is refused"         "nope does not exist" env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/nope"
  refuses "a missing directory is refused"    "its directory does not exist" env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/no/x"
  ln -s "$d/root/gone" "$d/root/dangling"
  refuses "a dangling link is refused"        "does not resolve" env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/dangling"
  expect "an unmarked root is refused"        3 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_MARKER=.other bash "$self" "$d/root/data/x"
  expect "no roots configured is refused"     3 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS= bash "$self" "$d/root/data/x"
  expect "without the grant it is a dry run"  0 bash "$self" "$d/root/data/x"
  [ -e "$d/root/data/x" ] || { echo "  FAIL dry run moved the file"; fails=$((fails+1)); }
  expect "a sibling sharing the root's prefix"  3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root-old/z"
  expect "the trash itself is refused"        3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/.trash/t/w"
  expect "the root's marker is refused"       3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/$MARKER"
  mkdir -p "$d/root/inner/.trash/t"; touch "$d/root/inner/$MARKER" "$d/root/inner/.trash/t/w" "$d/root/data/b1" "$d/root/data/b2"
  local nested="$d/root:$d/root/inner"
  expect "a nested root is refused"           3 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$nested" bash "$self" "$d/root/inner"
  expect "a nested root's trash is refused"   3 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$nested" bash "$self" "$d/root/inner/.trash/t/w"
  expect "a nested root's marker is refused"  3 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$nested" bash "$self" "$d/root/inner/$MARKER"
  expect "a batch with one refusal is refused" 3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/b1" "$d/outside/y" "$d/root/data/b2"
  [ -e "$d/root/data/b1" ] && [ -e "$d/root/data/b2" ] \
    || { echo "  FAIL a refused batch moved some of its paths"; fails=$((fails+1)); }
  touch "$d/root/inner/f" "$d/root/inner/g"
  expect "a nested path moves"                0 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$d/root/inner:$d/root" bash "$self" "$d/root/inner/f"
  expect "a nested path moves, outer first"   0 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$nested" bash "$self" "$d/root/inner/g"
  ls "$d"/root/inner/.trash/*/f "$d"/root/inner/.trash/*/g >/dev/null 2>&1 \
    || { echo "  FAIL a nested path went to the outer root's trash, not its own"; fails=$((fails+1)); }
  mkdir -p "$d/root/proj/in2"; touch "$d/root/proj/in2/$MARKER" "$d/root/data/c"; mkdir -p "$d/root/data/sub"; touch "$d/root/data/sub/e"
  expect "a parent of a nested root refused"  3 env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$d/root:$d/root/proj/in2" bash "$self" "$d/root/proj"
  expect "a path listed twice is refused"     3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/c" "$d/root/data/c"
  expect "a path inside another is refused"   3 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/sub" "$d/root/data/sub/e"
  [ -e "$d/root/proj/in2/$MARKER" ] && [ -e "$d/root/data/c" ] && [ -e "$d/root/data/sub/e" ] \
    || { echo "  FAIL a refused overlap or root parent moved something"; fails=$((fails+1)); }
  expect "a batch of two distinct paths moves" 0 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/b1" "$d/root/data/b2"
  [ ! -e "$d/root/data/b1" ] && [ ! -e "$d/root/data/b2" ] \
    || { echo "  FAIL a batch reported success and left a path behind"; fails=$((fails+1)); }
  # A failed move must not report "moved": a read-only directory stands in for an I/O failure.
  # Permissions do not bind root, so these two run only as a normal user.
  if [ "$(id -u)" != 0 ]; then
    mkdir -p "$d/root/ro"; touch "$d/root/ro/f"; chmod a-w "$d/root/ro"
    refuses "a move that fails is refused"    "could not move" env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/ro/f"
    chmod u+w "$d/root/ro"; chmod a-w "$d/root/.trash"
    refuses "no trash slot is refused"        "could not make a trash slot" env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/ro/f"
    chmod u+w "$d/root/.trash"
    [ -e "$d/root/ro/f" ] || { echo "  FAIL a refused move lost the file"; fails=$((fails+1)); }
  else skipped=" (as root: the two I/O-failure cases did not run; run as a normal user)"
  fi
  expect "with the grant it moves"            0 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/x"
  [ ! -e "$d/root/data/x" ] && ls "$d"/root/.trash/*/data/x >/dev/null 2>&1 \
    || { echo "  FAIL the file did not land in the trash"; fails=$((fails+1)); }
  echo v2 > "$d/root/data/x"
  expect "the same path again moves too"      0 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/data/x"
  [ "$(ls -d "$d"/root/.trash/*/data/x 2>/dev/null | wc -l)" = 2 ] \
    || { echo "  FAIL a second delete in the same second overwrote the first copy"; fails=$((fails+1)); }
  expect "a link inside the root moves"       0 env ALLOW_DESTRUCTIVE=1 bash "$self" "$d/root/current"
  [ ! -L "$d/root/current" ] && [ -e "$d/root/releases/v3/app" ] \
    || { echo "  FAIL deleting a link moved what it points to"; fails=$((fails+1)); }
  # Configuration from the project's files: a copy of this script in a throwaway git checkout.
  local p="$d/proj"; mkdir -p "$p/scripts" "$p/data/sub" "$p/other" "$p/code"
  cp "$self" "$p/scripts/safe-delete.sh"; git -C "$p" init -q
  touch "$p/data/$MARKER" "$p/other/$MARKER" "$p/data/f1" "$p/data/f2" "$p/data/f3" "$p/data/f4" "$p/other/o1"
  local ps="$p/scripts/safe-delete.sh"
  printf 'APP_ENV=dev\nSAFE_DELETE_ROOTS=data\nALLOW_DESTRUCTIVE=1\n' > "$p/.env"
  ( cd "$p/code" && env -u SAFE_DELETE_ROOTS bash "$ps" ../data/f1 ) >/dev/null 2>&1
  [ -e "$p/data/f1" ] || { echo "  FAIL ALLOW_DESTRUCTIVE in .env turned a dry run into a move"; fails=$((fails+1)); }
  expect "a relative root in .env, from a subdirectory" 0 sh -c "cd '$p/code' && env -u SAFE_DELETE_ROOTS ALLOW_DESTRUCTIVE=1 bash '$ps' ../data/f1"
  [ ! -e "$p/data/f1" ] || { echo "  FAIL a root from .env did not move the file"; fails=$((fails+1)); }
  refuses "the environment overrides .env"    "from the environment" env ALLOW_DESTRUCTIVE=1 SAFE_DELETE_ROOTS="$p/other" bash "$ps" "$p/data/f2"
  printf 'SAFE_DELETE_ROOTS="other"\n' > "$p/.safe-delete.conf"
  refuses ".env wins over .safe-delete.conf"  "is not strictly below" env -u SAFE_DELETE_ROOTS ALLOW_DESTRUCTIVE=1 bash "$ps" "$p/other/o1"
  rm "$p/.env"
  expect "a quoted root in .safe-delete.conf" 0 env -u SAFE_DELETE_ROOTS ALLOW_DESTRUCTIVE=1 bash "$ps" "$p/other/o1"
  printf 'SAFE_DELETE_ROOTS=$(touch %s/pwned)data\n' "$d" > "$p/.env"
  refuses "a .env value is never run"         "is not strictly below" env -u SAFE_DELETE_ROOTS ALLOW_DESTRUCTIVE=1 bash "$ps" "$p/data/f3"
  [ ! -e "$d/pwned" ] || { echo "  FAIL a command in .env ran"; fails=$((fails+1)); }
  rm "$p/.env" "$p/.safe-delete.conf"
  refuses "no roots anywhere is refused"      "from nowhere" env -u SAFE_DELETE_ROOTS ALLOW_DESTRUCTIVE=1 bash "$ps" "$p/data/f4"
  [ "$fails" = 0 ] && echo "self-test: all cases behave${skipped:-}" || echo "self-test: $fails broken${skipped:-}"
  return "$fails"
}

if [ $# -eq 0 ]; then sed -n '/^#   safe-delete.sh PATH/,/^#   safe-delete.sh --self-test/p' "$0" | sed 's/^# \{0,1\}//'; exit 2; fi
case "$1" in
  --self-test) self_test; exit $? ;;
  -h|--help) sed -n '/^#   safe-delete.sh PATH/,/^#   safe-delete.sh --self-test/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac  # an empty first argument falls through to delete_one, which refuses it
# Check every path before moving any, so a refusal never leaves a batch half done (found in review) -
# including a path listed twice or inside another listed path, which is gone by its turn (round
# eleven).
all=()
for p in "$@"; do n="$( CHECK_ONLY=1 delete_one "$p" )" || exit 3; all+=("$n"); done
for i in "${!all[@]}"; do for j in "${!all[@]}"; do
  [ "$i" = "$j" ] && continue
  case "${all[i]}" in "${all[j]}"|"${all[j]}"/*) refuse "${all[i]} is listed twice, or inside ${all[j]}" ;; esac
done; done
for p in "$@"; do delete_one "$p"; done
