
Concepts
========

This file documents the various concepts that are used throughout ftw, and
should serve as a reference point.


Event
-----

### Descr

An event is a single or multi-day dance event, for which some competition
results are either archived or currently being stored and updated.

### Examples

Examples of events include: P4T, 4TWC, Spooky Cup, Switch4Us

### Data

- A name
- A date span (start/end)
- A list of competitions
- Mapping between competitors/dancers and bib numbers
  Note: a competitor may have multiple bib numbers (e.g. one as a leader, one as a follower),
  or have the same bib number for both roles


Competition
-----------

### Descr

An event may hold one or multiple competitions during its length. A competition
is a single coherent set of phases, from preliminaries to finals. Each competition
corresponds (at least) to a single final and its associated ranking (but may also
recors more data, such as intermediary results, etc...).

### Example

Examples of competitions include: the Initiés division of P4T, or the Inter
division of P4T, or the single (strictly) division of Switch4Us

### Data

- A name
- Its parent Event
- Its kind: Jack&Jill, Strictly, Routine
- An (optional) division
- A list of phases


Phase
-----

### Descr

A competition is divided into phases, where each phase establishes a (potentially partial)
ranking beetween competitors, resulting in either the final ranking of the competition, or
in an elimination phase, where the first <n> competitors are promoted to the next phase of
the competition.

### Examples

Prelims (of the Initié division of the P4T), Semifinal, Finals

### Data

- Parent competition
- Phase order: Finals, Semifinals, quarter-finals, preliminaries, ...
- Artefact kind for judges
  + artefact kinds for head judge
  + ranking algorithm
- List of Judges (judges for leaders, for follows, for couples + head judge)
- List of competitors/targets (cf pairings)
- Associated artefacts (for each pair judge/target) and ranking of targets


Pairing
-------

### Descr

Some phases of competitions require judging couples, even though dancers
are individually registered, for examples during the finals of a Jack&Jill,
or during an All-In. In those cases, the phase needs a pairings, which
indicates the list of couples for the phase.

### Data

- A list of a pair of dancers
- The partner of a given dancer can be looked up efficiently



Artefact
--------

### Descr

Artefacts are the result of judging. During each phase, judges assign artefacts
to each judging target.

### Example

Examples include: Yes/Alt/No for technique/musicality/teamwork (e.g. for prelims),
Individual judge ranking (for finals), ...

### Data

An artefact can be either:
- Mutliple Yes/Alt/No (e.g. for each of technique/teamwork/musicality)
- Single Yes/Alt/No + decimal number (0. - 0.9) (e.g. for head judges)
- simple decimal number (0. - 0.9) (for group decisions by judges)
- Individual judge ranking

Note: There may be new artefacts kinds/formats added regularly for new competitions.


Ranking algorithm
-----------------

### Descr

A ranking algorithm gives meaning to artefacts by generating a ranking from a list
of judgements artefacts. Ranking algorithm are typically only compatible with a
set number of artefact format (e.g. RPSS only works when artefacts are individual judge
rankings).

### Examples

For simples notes, one algorithm may be to sum up notes from all judges and compare
these sums (or averages); may be lexicographic order on the number of Yes/Alt/No;
RPSS for finals ranking, etc...

### Data

Accepted ranking algorithm:
1) Numeric values for Yes/Alt/No, then sum (e.g. 3/2/1)
   (note that the numeric values may change and depend on the criterion,
   e.g. 3/2/1 but 4/2/4 for technique)
2) Lexicographic order on the number of Yes/Alt/No (may be simulated by
   choosing adequate numeric values with algorithm 1)
3) RPSS
4) Condorcet method (TODO)

Note: new ranking method may be added from time to time, though less often
than new artefact kinds/formats.

Target
------

### Descr

A competition phase aims at ranking a set of targets. These targets are the subject
of artefacts emitted by judges.

### Examples

Targets can be either individual dancers (e.g. in a Jack&Jill), or couples (e.g. in a strictly,
or All-In).

### Data

A target is either:
- an individual dancer
- a couple of dancers (leader-follower)


Judge
-----

A Judge is just a dancer.

Dancer
------

### Descr

Someone who dances, ^^

### Examples

You, me, everybody !

### Data

- SCR4T Number (unique id)
- First Name, Last Name
- email address


