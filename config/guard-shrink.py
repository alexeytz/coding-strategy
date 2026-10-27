#!/usr/bin/env python3
"""guard-shrink - refuse a delete driven by an authority that looks short.

Why: a sync that deletes whatever is missing from the source deletes nearly everything when the
source is empty, cut short or from the wrong environment, and is correct by its own logic while
doing it. Call this before the delete; it refuses on the counts. More: config/README.md.

Rule 13.2: before deleting from one store on the strength of another, refuse if the authority is
empty, smaller, disjoint or uncountable. Prose did not hold this for a weaker model even with the
rule in its context (the skill's agent trials), so put it on the path the sync already takes:
call this before the delete, and let its exit code decide.

    guard-shrink.py --authority-count N --target-count M [--declared D] [--max-drop 0.05]
                    [--delete-count K] [--overlap-count O]
    guard-shrink.py --authority FILE --target-count M [--manifest FILE.json] [...as above]
    guard-shrink.py --self-test

FILE is counted as CSV records (quoted newlines are one record; the header excluded with
--header). A manifest is JSON with an integer "rows" field: what the source says it sent.
--delete-count is the number of rows the sweep is about to remove; without it the script assumes
target minus authority, which undercounts when the authority holds keys the target lacks.
--overlap-count is how many of the target's keys the authority also holds: 0 is the wrong
environment, same size or not. Counts cannot see keys, so the disjoint check exists only when
the caller passes it. --max-drop is a fraction in [0, 1). Exit 0 when the delete may go ahead, 3
when it is refused, 2 on bad input - also a refusal. It prints the predicate it decided on, so
the exit code and the printed reason cannot disagree (13.5).

Install: copy into the project (e.g. scripts/guard-shrink.py) and call it from the sync step:

    python3 scripts/guard-shrink.py --authority exports/today.csv --header \\
        --manifest exports/today.manifest.json --target-count "$(sqlite3 cache.db 'select count(*) from items')" \\
        --overlap-count "$SHARED" || exit 1

where SHARED is how many of the target's keys appear in the authority, which the sweep already
computes to know what to delete. Leave it out and the disjoint and delete-count checks do not run.
"""
import argparse
import contextlib
import csv
import io
import json
import os
import sys
import tempfile

REFUSE, BAD = 3, 2


def count_lines(path, header):
    # Records, not lines: a quoted field with a newline in it would count twice and make a short
    # authority look longer, the unsafe direction (found in review, 2026-10-20).
    with open(path, newline="") as f:
        n = sum(1 for row in csv.reader(f) if any(c.strip() for c in row))
    return n - 1 if header and n else n


def decide(authority, target, declared=None, max_drop=0.05, delete=None, overlap=None):
    """(ok, reason). Every refusal names the numbers it compared."""
    if authority <= 0:
        return False, f"authority is empty ({authority} rows): refusing to delete on its strength"
    if declared is not None and authority < declared:
        return False, f"authority has {authority} rows but declares {declared}: it is short, refusing"
    if overlap is not None and overlap == 0 and target > 0:
        return False, (f"authority shares none of the target's {target} keys: "
                       "wrong source or wrong environment, refusing")
    removed = delete if delete is not None else max(target - authority, 0)
    if overlap is not None:  # the target keys the authority lacks are what the sweep removes:
        removed = max(removed, target - overlap)  # 1 shared key in 1000 is 999 deletes (found in review)
    if delete is not None and authority < delete:
        return False, f"authority has {authority} rows, fewer than the {delete} about to be deleted: refusing"
    if target > 0 and removed / target > max_drop:
        return False, (f"syncing would remove {removed} of {target} rows "
                       f"({removed / target:.0%} > {max_drop:.0%} allowed): refusing")
    return True, f"authority {authority} rows, target {target}, removing {removed}: within limits"


def self_test():
    # Each refusal has a case that only it refuses, so deleting any one check fails the self-test.
    cases = [((0, 0), False),                         # empty: refused even with nothing to delete
             ((0, 400), False),
             ((400, 405, 410), False),                # short of its manifest, inside the drop limit
             ((1000, 1000, None, 0.05, None, 0), False),   # disjoint: same size, no shared key
             ((10, 1000, None, 0.05, 12, None), False),    # fewer rows than the deletes, under 5%
             ((380, 412), False),                     # drop over the limit
             ((1000, 1000, None, 0.05, 200, None), False),  # stated deletes over the limit
             ((410, 412, 410), True), ((412, 412), True), ((5, 0), True),
             ((1000, 1000, None, 0.05, 3, 990), True),
             ((1000, 1000, None, 0.05, None, 1), False),     # one shared key: 999 to delete
             ((10, 1000, None, 0.05, 10, None), True),       # deletes equal to the authority
             ((95, 100), True),                              # exactly the limit
             ((1000, 1000, None, 0.05, 3, 1), False),        # stated deletes do not hide the overlap's 999
             ((1000, 1000, None, 0.05, None, 950), True),    # overlap at exactly the limit
             ((1000, 1000, None, 0.05, None, 949), False),   # one past it
             ((10, 1000, None, 0.05, 11, None), False)]      # one more delete than the authority holds
    cases.append(((5, 0, None, 0.05, None, 0), True))    # empty target: nothing to call disjoint
    bad = [(args, want) for args, want in cases if decide(*args)[0] != want]
    # The drop limit also refuses a disjoint authority (it implies removing the whole target);
    # the disjoint check is what names it, so the reason is what this case tests (13.5).
    for t in (1000, 1):  # a one-row target is disjoint too
        if "shares none" not in decide(1000, t, None, 0.05, None, 0)[1]:
            bad.append(("disjoint reason", t))
    d = tempfile.mkdtemp()
    p = os.path.join(d, "a.csv")
    open(p, "w").write('sku,name\nA,"one\ntwo"\nB,2\n\n')
    if count_lines(p, header=True) != 2:
        bad.append(("count_lines", 2))
    # Through main(), so a refusal's exit code is tested and not only its decision.
    for name, body in (("true.json", '{"rows": true}'), ("none.json", "{}"), ("neg.json", '{"rows": -1}')):
        open(os.path.join(d, name), "w").write(body)
    big = os.path.join(d, "big.csv")  # a field past the csv module's limit is bad input, not a crash
    open(big, "w").write("a," + "x" * (csv.field_size_limit() + 1) + "\n")
    for argv, want in [(["--authority", os.path.join(d, "missing.csv"), "--target-count", "4"], BAD),
                       (["--authority", p, "--manifest", os.path.join(d, "true.json"), "--target-count", "2"], BAD),
                       (["--authority", p, "--manifest", os.path.join(d, "none.json"), "--target-count", "2"], BAD),
                       (["--authority", p, "--manifest", os.path.join(d, "neg.json"), "--target-count", "2"], BAD),
                       (["--authority-count", "10", "--target-count", "10", "--declared", "-1"], BAD),
                       (["--authority-count", "10", "--target-count", "10", "--delete-count", "-1"], BAD),
                       (["--authority-count", "10", "--target-count", "10", "--overlap-count", "-1"], BAD),
                       (["--authority-count", "10", "--target-count", "10", "--overlap-count", "11"], BAD),
                       (["--authority-count", "10", "--target-count", "10", "--overlap-count", "10"], 0),
                       (["--authority-count", "5", "--target-count", "10", "--overlap-count", "6"], BAD),
                       (["--authority-count", "10", "--target-count", "5", "--overlap-count", "6"], BAD),
                       (["--authority", big, "--target-count", "1"], BAD),
                       (["--authority-count", "10", "--target-count", "1000", "--max-drop", "5"], BAD),
                       (["--authority-count", "10", "--target-count", "10", "--max-drop", "1"], BAD),  # the bound itself
                       (["--authority-count", "10", "--target-count", "-1"], BAD),
                       (["--authority-count", "1", "--target-count", "100"], REFUSE)]:
        sys.argv = ["guard-shrink.py"] + argv
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            got = main()
        if got != want:
            bad.append((argv, f"exit {got}, want {want}"))
    for b in bad:
        print(f"self-test FAILED: {b}")
    print("self-test: all cases decide as expected" if not bad else "self-test: broken")
    return 0 if not bad else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--authority")
    ap.add_argument("--authority-count", type=int)
    ap.add_argument("--header", action="store_true", help="the authority file's first line is a header")
    ap.add_argument("--manifest")
    ap.add_argument("--declared", type=int)
    ap.add_argument("--target-count", type=int)
    ap.add_argument("--max-drop", type=float, default=0.05)
    ap.add_argument("--delete-count", type=int)
    ap.add_argument("--overlap-count", type=int)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    try:
        authority = a.authority_count if a.authority_count is not None else count_lines(a.authority, a.header)
        declared = a.declared
        if a.manifest:
            declared = json.load(open(a.manifest))["rows"]
            if isinstance(declared, bool) or not isinstance(declared, int):
                raise ValueError(f"manifest rows is {declared!r}, not an integer")
        # A negative declared count can never exceed the authority, so it switched the short-authority
        # refusal off (found in review).
        if declared is not None and declared < 0:
            raise ValueError(f"the declared row count is {declared}, negative")
        if a.target_count is None:
            raise ValueError("--target-count is required")
        # 5 meant as "5%" or a nan would switch the threshold off; a negative count is a bug upstream.
        if not 0 <= a.max_drop < 1:
            raise ValueError(f"--max-drop is a fraction in [0, 1), got {a.max_drop}")
        for name in ("target_count", "delete_count", "overlap_count"):
            if (getattr(a, name) or 0) < 0:
                raise ValueError(f"--{name.replace('_', '-')} is negative")
        if a.overlap_count is not None and a.overlap_count > min(a.target_count, authority):
            raise ValueError(f"--overlap-count {a.overlap_count} exceeds the keys either side holds")
    except (OSError, ValueError, KeyError, TypeError, csv.Error) as e:
        print(f"guard-shrink: cannot decide ({e}): refusing", file=sys.stderr)  # uncountable is a refusal
        return BAD
    ok, reason = decide(authority, a.target_count, declared, a.max_drop, a.delete_count, a.overlap_count)
    print(("ok: " if ok else "REFUSED: ") + reason)
    return 0 if ok else REFUSE


if __name__ == "__main__":
    sys.exit(main())
