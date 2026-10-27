# 13 Data architecture

Part of the `coding-strategy` skill - routing table in [SKILL.md](../SKILL.md).

One job: **you have more than one copy of the data.** A cache, a search index, a vector
store, a denormalised table, a read replica. The rules below all answer one question -
which copy is authoritative, how is every other copy rebuilt from it, and what must a
process prove before it deletes from one on the strength of another. Where code goes is
[2](02-layout.md); config layout is [3](03-configuration.md).

**Rules**

- Name the source of truth in one sentence; a derived store that cannot be rebuilt from it is an undeclared second source (13.1)
- Before deleting from one store on the strength of another, refuse if the authority is empty, short of its manifest or of the deletes, disjoint, or uncountable; `config/guard-shrink.py` does it, and checks only what it is given: without `--delete-count` or `--overlap-count` the delete check does not run, without `--overlap-count` the disjoint check does not (13.2)
- Namespace a derived store by what determines its semantics, never by a property that merely correlates (13.3)
- On a shared real service, tests get their own prefix and refuse to run without one (13.4)
- Ship a sync check with an exit code derived from the predicate it prints (13.5)

### 13.1 Name the source of truth in one sentence

"The relational database is the source of truth; the vector store holds vectors derived
from it and can always be rebuilt." That sentence drives every recovery path there is -
what to rebuild, which side to believe when they disagree, and what a sync check is
checking. **A derived store that cannot be rebuilt from the source is a second source of
truth that nobody declared**, and you will find out which it is during an incident.

### 13.2 A destructive reconciliation proves it has authority before it deletes

An orphan
sweep that deletes index entries whose key is missing from the database is correct right
up until the database it is reading is the wrong one - empty, partially loaded, or
pointed at a different environment. Two incidents in one project wiped 44 and then ~90
vectors exactly that way. Before deleting on the strength of another store, refuse when:

- the authority has no active rows at all,
- it has fewer rows than the number of items about to be deleted, or than the source's own
  declared count when you have one (a manifest),
- it shares none of the specific keys under consideration, or
- the count could not be taken.

Dry-run defaults ([11.7](11-resilient-code.md)) do not cover this.
This is maintenance that runs on its own schedule, not a user-invoked destructive action,
so nobody is watching for the confirmation prompt.

Put the refusal on the sync's path rather than in a reviewer's memory: [`guard-shrink.py`](../config/guard-shrink.py) compares counts, so it refuses an empty, short or uncountable authority and a delete over its limit, but sees a disjoint one only if you pass how many target keys the authority holds - computing that is yours ([24.5](24-quality-gates.md)).

### 13.3 Namespace a derived store by whatever determines its semantics, not by a proxy

Name
a vector collection for the embedding model, not the dimension: two different 4096-dim
models share a size and not an embedding space, so a dimension check passes while
silently mixing two incompatible spaces. The general form - key the namespace on the
thing that would make two datasets incomparable, and never on a property that merely
correlates with it.

### 13.4 Give tests their own namespace on a shared real service

[14.1](14-writing-tests.md) says temp dirs and mocked externals, which is not
available when the external *is* a real shared service you cannot mock. Then isolation
is a configurable prefix or collection name the suite sets, verified before the first
test writes anything. One project's suite wrote into live production data until it got
one. Where that prefix is missing, the correct behaviour is to refuse to run.

### 13.5 A sync check is a first-class operation, not a debugging convenience

Ship the
command that answers "do these two stores still agree", give it an exit code derived from
the same predicate its report prints ([17.6](17-numbers-you-can-publish.md)),
and run it before and after anything that touches both. It is also what makes
[19.1](19-instrumentation.md)'s "believe the system's own health check"
actionable rather than aspirational - without it, there is no health check to believe.

### 13.6 When this does not apply

One store, no cache, no index: skip it entirely. The
moment you add the second copy, come back - the cost of these rules is small and the cost
of learning them from an incident is not.
