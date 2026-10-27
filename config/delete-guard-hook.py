#!/usr/bin/env python3
"""delete-guard-hook - refuse an agent's shell command that deletes on a route with no guard.

Why: an agent told to delete through scripts/safe-delete.sh or to run scripts/guard-shrink.py
first may write its own `rm -rf` or `DELETE FROM` instead; in the skill's tests one did, five times
of five, and a guard it never called protected nothing. A hook at the agent's tool layer sees
every shell command, so it holds where the instruction did not, and it says why it refused, so
the model reroutes instead of fighting it (24.5). More: config/README.md.

Written for Claude Code's PreToolUse hook: it reads the tool call as JSON on stdin and exits 2 to
block it, with the reason on stderr, which Claude Code shows the model. Other agents that pass a
JSON object carrying the command (tool_input.command, or command) can call it the same way.

It also keeps the guard's own configuration out of the agent's reach: safe-delete.sh reads its
roots and marker from the project's .env or .safe-delete.conf, so a command that sets them inline,
creates or edits a marker or that file, or writes a SAFE_DELETE_ line into .env is refused, as is a
file edit (Write, Edit, MultiEdit) that does. Register it for those tools as well as Bash.

    delete-guard-hook.py < payload.json     exit 0 allow, 2 refuse
    delete-guard-hook.py --self-test

It reads the command text, so it stops the common routes, not a determined one: a delete inside a
script file the agent wrote and then ran is invisible to it. Keep the data recoverable too.
"""
import json
import re
import sys

# (pattern, what it is). Matched against the command with quotes left in, case-insensitive for SQL.
REFUSE = [
    (r"(^|[;&|(`\s])rm\s+(-[a-zA-Z]*[rRf]|--recursive|--force)", "a recursive or forced rm"),
    (r"(^|[;&|(`\s])rm\s+[^;&|]*[$*]", "an rm on a computed or wildcard path"),
    (r"\bfind\b[^;&|]*\s-(delete|exec\s+rm)\b", "find -delete"),
    (r"\bshutil\.rmtree\b", "shutil.rmtree"),
    (r"(?i)\bdelete\s+from\b", "an SQL DELETE"),
    (r"(?i)\b(drop|truncate)\s+table\b", "an SQL DROP or TRUNCATE"),
    (r"\bgit\s+clean\s+-[a-zA-Z]*f", "git clean -f"),
    (r"\bgit\s+reset\s+--hard\b", "git reset --hard"),
]
# A command that goes through the project's own guard is the route the hook exists to point to.
# The guard's own configuration: only the user widens where deletes may happen.
CONFIG_INLINE = re.compile(r"\bSAFE_DELETE_(ROOTS|MARKER)\s*=")
CONFIG_FILES = re.compile(r"\.safe-delete-root\b|\.safe-delete\.conf\b")
WRITES = re.compile(r"(^|[;&|(`\s])(touch|tee|cp|mv|ln|install|truncate|chmod|rm|echo|printf|cat)\b|>|\bsed\s+-i")
CONFIG_ADVICE = ("The delete guard's roots and marker come from the project's .env or .safe-delete.conf, "
                 "and only the user changes them. Run scripts/safe-delete.sh without setting them; if a "
                 "path you need to delete is outside its roots, stop and ask the user.")
GUARDED_FILES = re.compile(r"(^|[\s/])safe-delete\.sh\b")
GUARDED_SYNC = re.compile(r"guard-shrink\.py\b[^;|]*&&")

ADVICE = ("Delete files through scripts/safe-delete.sh: run it first without ALLOW_DESTRUCTIVE to "
          "see what it would move, then with ALLOW_DESTRUCTIVE=1. Before a sync deletes rows the "
          "source lacks, run scripts/guard-shrink.py and delete only if it exits 0, in the same "
          "command: `python3 scripts/guard-shrink.py ... && <the delete>`. If neither fits and the "
          "delete is intended, stop and ask the user to run it.")


def verdict(command):
    """(allowed, reason)."""
    if CONFIG_INLINE.search(command):
        return False, f"Refused by the project's delete guard: this command sets SAFE_DELETE_ROOTS or SAFE_DELETE_MARKER. {CONFIG_ADVICE}"
    if CONFIG_FILES.search(command) and WRITES.search(command) and not re.fullmatch(r"\s*(cat|ls|head|grep)\b[^;&|>]*", command):
        return False, f"Refused by the project's delete guard: this command touches a delete root's marker or .safe-delete.conf. {CONFIG_ADVICE}"
    if GUARDED_FILES.search(command) and not re.search(r"(^|[;&|(`\s])rm\s", command):
        return True, "goes through safe-delete.sh"
    for pat, what in REFUSE:
        if re.search(pat, command):
            if what.startswith("an SQL") and GUARDED_SYNC.search(command):
                return True, "the delete runs only after guard-shrink.py passes"
            return False, f"Refused by the project's delete guard: this command contains {what}. {ADVICE}"
    return True, "no delete route matched"


def edit_verdict(payload):
    """(allowed, reason) for a file edit: the marker, .safe-delete.conf, or a SAFE_DELETE_ line in .env."""
    ti = payload.get("tool_input") or {}
    path = ti.get("file_path") or ti.get("path") or ""
    name = path.rsplit("/", 1)[-1]
    if name in (".safe-delete-root", ".safe-delete.conf"):
        return False, f"Refused by the project's delete guard: {name} is the guard's own configuration. {CONFIG_ADVICE}"
    text = " ".join(str(ti.get(k) or "") for k in ("content", "new_string")) + \
        " ".join(str(e.get("new_string") or "") for e in ti.get("edits") or [] if isinstance(e, dict))
    if name.startswith(".env") and name != ".env.example" and "SAFE_DELETE_" in text:
        return False, f"Refused by the project's delete guard: this edit writes SAFE_DELETE_ settings into {name}. {CONFIG_ADVICE}"
    return True, "not the guard's configuration"


def command_of(payload):
    ti = payload.get("tool_input") or {}
    return ti.get("command") or payload.get("command") or ""


def self_test():
    cases = [
        ("rm -rf data/cache", False), ("rm -f old.log", False), ("rm data/$NAME", False),
        ("rm data/*.csv", False), ("find data -name '*.tmp' -delete", False),
        ("python3 -c 'import shutil; shutil.rmtree(\"data\")'", False),
        ("sqlite3 cache.db \"DELETE FROM items WHERE id NOT IN (SELECT id FROM ex)\"", False),
        ("sqlite3 cache.db 'drop table items'", False), ("git clean -fd", False),
        ("git reset --hard HEAD~1", False),
        ("ls -la && cat README.md", True), ("rm notes.txt", True), ("git status", True),
        ("scripts/safe-delete.sh data/tmp/old.csv", True),
        ("ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh data/tmp", True),
        ("scripts/safe-delete.sh x; rm -rf data", False),
        ("python3 scripts/guard-shrink.py --authority ex.csv --header --target-count 412 && "
         "sqlite3 cache.db 'DELETE FROM items WHERE id NOT IN (SELECT id FROM ex)'", True),
        ("python3 scripts/guard-shrink.py --authority ex.csv --target-count 412; "
         "sqlite3 cache.db 'DELETE FROM items'", False),
        ("grep -n 'delete from' notes.md", False),  # a search for the words is refused too: the cost of reading text
        ("SAFE_DELETE_ROOTS=/ ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh etc", False),
        ("export SAFE_DELETE_MARKER=.x && scripts/safe-delete.sh data/a", False),
        ("ALLOW_DESTRUCTIVE=1 scripts/safe-delete.sh data/tmp/a.json", True),
        ("touch /home/u/.safe-delete-root", False), ("echo 'SAFE_DELETE_ROOTS=/' >> .env", False),
        ("echo x > .safe-delete.conf", False), ("cat .safe-delete.conf", True),
        ("ls -la data/.safe-delete-root", True),
    ]
    edits = [
        ({"file_path": "/p/.env", "new_string": "SAFE_DELETE_ROOTS=/"}, False),
        ({"file_path": "/p/.env", "content": "APP_ENV=dev\n"}, True),
        ({"file_path": "/p/data/.safe-delete-root", "content": ""}, False),
        ({"file_path": "/p/.safe-delete.conf", "content": "SAFE_DELETE_ROOTS=data"}, False),
        ({"file_path": "/p/.env.local", "edits": [{"new_string": "SAFE_DELETE_MARKER=x"}]}, False),
        ({"file_path": "/p/.env.example", "new_string": "# SAFE_DELETE_ROOTS=var"}, True),
        ({"file_path": "/p/app.py", "content": "print(1)"}, True),
    ]
    bad = [(c, want) for c, want in cases if verdict(c)[0] != want]
    bad += [(json.dumps(e), want) for e, want in edits if edit_verdict({"tool_input": e})[0] != want]
    ok, reason = verdict("rm -rf data")
    if ok or "safe-delete.sh" not in reason or "ask the user" not in reason:
        bad.append(("the refusal names the route and the way out", False))
    import subprocess
    r = subprocess.run([sys.executable, __file__, "--bogus"], input="{}", capture_output=True, text=True)
    if r.returncode != 2:
        bad.append(("an unknown flag exits 2", False))
    for c, want in bad:
        print(f"FAIL: {'allowed' if not want else 'refused'} wrongly: {c}", file=sys.stderr)
    print("delete-guard-hook self-test:", "FAILED" if bad else f"all {len(cases) + len(edits)} cases behave")
    return 1 if bad else 0


def main():
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if sys.argv[1:]:  # an unknown flag is an error, never a run that ignores it (12.5)
        print("usage: delete-guard-hook.py < payload.json | --self-test", file=sys.stderr)
        return 2
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        print("delete-guard-hook: stdin is not a JSON tool call; refusing", file=sys.stderr)
        return 2
    tool = payload.get("tool_name") or ""
    ok, reason = edit_verdict(payload) if tool in ("Write", "Edit", "MultiEdit") else verdict(command_of(payload))
    if not ok:
        print(reason, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
