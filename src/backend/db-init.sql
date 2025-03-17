DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS competition_kinds;
DROP TABLE IF EXISTS competition_categories;
DROP TABLE IF EXISTS competitions;
DROP TABLE IF EXISTS dancers;
DROP TABLE IF EXISTS bibs;
DROP TABLE IF EXISTS judging_types;
DROP TABLE IF EXISTS judges;
DROP TABLE IF EXISTS phases;
DROP TABLE IF EXISTS rounds;
DROP TABLE IF EXISTS heats;
DROP TABLE IF EXISTS couple_heats;
DROP TABLE IF EXISTS artefacts;
DROP TABLE IF EXISTS bonus_artefacts;
DROP TABLE IF EXISTS couple_artefacts;
DROP TABLE IF EXISTS couple_bonus_artefacts;
DROP TABLE IF EXISTS divisions;
DROP TABLE IF EXISTS couple_bonus_artefacts;


BEGIN;

CREATE TABLE events (
  id INTEGER PRIMARY KEY,
  name TEXT,
  start_date TEXT,
  end_date TEXT
);


CREATE TABLE competition_kinds ( -- JnJ, Strictly, Routime, …
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE
);

CREATE TABLE competition_categories ( -- division (initie, inter, advanced, …) or not scr4t (invit, …)
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE
);


CREATE TABLE competitions (
  id INTEGER PRIMARY KEY,
  event INTEGER REFERENCES events(id),
  name TEXT,
  kind INTEGER REFERENCES competition_kinds(id),
  category INTEGER REFERENCES competition_categories(id)
);


CREATE TABLE division_names (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
);

CREATE TABLE dancers (
    id INTEGER PRIMARY KEY,
    birthday TEXT,
    last_name TEXT,
    first_name TEXT,
    email TEXT UNIQUE,
    as_leader INTEGER REFERENCES divisions(id),
    as_follower INTEGER REFERENCES divisions(id)
);


CREATE TABLE bibs (
    dancer_id INTEGER  REFERENCES dancers(id),
    competition_id INTEGER REFERENCES competitions(id),
    -- in case of couple, give them both the same bib
    bid_id INTEGER NOT NULL,
    role TEXT NOT NULL,

    PRIMARY KEY(bid_id, competition_id, role)
    -- allow to work with either 
    -- * same bib for dancer as lead and follow
    -- * different bibs for leaders and followers
);


CREATE TABLE judging_types (
    id PRIMARY KEY,
    judging_type TEXT UNIQUE -- head or lead or follow or couple
);

CREATE TABLE judges (
    judge_id INTEGER REFERENCES dancers(id),
    phase_id INTEGER REFERENCES phases(id),
    judging INTEGER REFERENCES judging_types(id),
    PRIMARY KEY(judge_id, phase_id)
);

CREATE TABLE rounds (
    id INTEGER PRIMARY KEY, -- 0 = finale, 1 = prelim, 2 = semi, …
    name TEXT UNIQUE -- finale, prelim, semi, quarter, …
);

CREATE TABLE phases (
    id INTEGER PRIMARY KEY,
    competition_id INTEGER REFERENCES competitions(id),
    round INTEGER REFERENCES rounds(id),
    artefact_description_judges TEXT,
    artefact_description_head_judge TEXT,
    ranking_algorithm TEXT, -- don't ref to algorithm types because can includes parameters
    UNIQUE(competition_id, round)
);


CREATE TABLE heats (
    id INTEGER PRIMARY KEY, -- = target id of judgement
    phase_id INTEGER REFERENCES phases(id),
    heat_number INTEGER NOT NULL,
    bib_id INTEGER
    -- no unique constraint because a dancer can be in several heats
    -- some of them without being scored
);

CREATE TABLE artefacts (
    target_id INTEGER REFERENCES heats(id), -- = target id of judgement
    judge INTEGER REFERENCES dancers(id),
    artefact INTEGER NOT NULL, -- encoding of judgements
    PRIMARY KEY(target_id, judge)
);

CREATE TABLE bonus_artefacts (
    target_id INTEGER REFERENCES heats(id), -- = target id of judgement
    bonus INTEGER NOT NULL, -- encoding of bonus
    PRIMARY KEY(target_id)
);


-- TODO: could we spare couple tables with the same bid for both dancers in bib
CREATE TABLE couple_heats (
    id INTEGER PRIMARY KEY, -- = target id of judgement
    phase_id INTEGER REFERENCES phases(id),
    heat_number INTEGER NOT NULL,
    lead_dancer_id INTEGER REFERENCES dancers(id),
    follow_dancer_id INTEGER REFERENCES dancers(id),
    UNIQUE(phase_id, heat_number, lead_dancer_id, follow_dancer_id)
);

CREATE TABLE couple_artefacts (
    target_id INTEGER REFERENCES couple_heats(id), -- = target id of judgement
    judge INTEGER REFERENCES dancers(id),
    artefact INTEGER NOT NULL, -- encoding of judgements
    PRIMARY KEY(target_id, judge)
);

CREATE TABLE couple_bonus_artefacts (
    target_id INTEGER REFERENCES couple_heats(id), -- = target id of judgement
    bonus INTEGER NOT NULL, -- encoding of bonus
    PRIMARY KEY(target_id)
);

COMMIT;

