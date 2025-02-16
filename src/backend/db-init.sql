
DROP TABLE
    events,
    competition_kinds,
    competition_categories,
    competitions,
    dancers,
    single_bibs,
    couple_bibs,
    judging_types,
    judges,
    phases,
    single_heats,
    couple_heats,
    single_artifacts,
    single_bonus_artifacts,
    double_artifacts,
    double_bonus_artifacts;


BEGIN;

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY,
  name TEXT,
  start_date TEXT,
  end_date TEXT
);


CREATE TABLE IF NOT EXISTS competition_kinds ( -- JnJ, Strictly, Routime, …
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS competition_categories ( -- division (initie, inter, advanced, …) or not scr4t (invit, …)
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE
);


CREATE TABLE IF NOT EXISTS competitions (
  id INTEGER PRIMARY KEY,
  event INTEGER REFERENCES events(id),
  name TEXT,
  kind INTEGER REFERENCES competition_kinds(id),
  category INTEGER REFERENCES competition_categories(id)
);


CREATE TABLE IF NOT EXISTS divisions (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS dancers (
    id INTEGER PRIMARY KEY,
    birthday TEXT,
    last_name TEXT,
    first_name TEXT,
    email TEXT UNIQUE,
    as_leader INTEGER REFERENCES divisions(id),
    as_follower INTEGER REFERENCES divisions(id)
);


CREATE TABLE IF NOT EXISTS bibs (
    dancer_id INTEGER  REFERENCES dancers(id),
    competition_id INTEGER REFERENCES competitions(id),
    -- in case of couple, give them both the same bib
    bid_id INTEGER NOT NULL,
    role TEXT NOT NULL,

    PRIMARY KEY(bid_id, competition_id, role) -- allow to work with either same bid for dancer as lead and follorw, or different bibs
);


CREATE TABLE IF NOT EXISTS judging_types (
    id PRIMARY KEY,
    judging_type TEXT UNIQUE -- head or lead or follow or couple
);

CREATE TABLE IF NOT EXISTS judges (
    judge_id INTEGER REFERENCES dancers(id),
    phase_id INTEGER REFERENCES phases(id),
    judging INTEGER REFERENCES judging_types(id),
    PRIMARY KEY(judge_id, phase_id)
);

CREATE TABLE if not EXISTS round_types (
    id INTEGER PRIMARY KEY, -- 0 = finale, 1 = prelim, 2 = semi, …
    name TEXT UNIQUE -- finale, prelim, semi, quarter, …
);

CREATE TABLE IF NOT EXISTS phases (
    id INTEGER PRIMARY KEY,
    competition_id INTEGER REFERENCES competitions(id),
    round INTEGER REFERENCES round_types(id),
    artifact_description_juges TEXT,
    artifact_description_head_juge TEXT,
    ranking_algorithm TEXT, -- don't ref to algorithm types because can includes parameters
    UNIQUE(competition_id, round)
);


CREATE TABLE IF NOT EXISTS heats (
    id INTEGER PRIMARY KEY, -- = target id of judgement
    phase_id INTEGER REFERENCES phases(id),
    heat_number INTEGER NOT NULL,
    bib_id INTEGER
);

CREATE TABLE IF NOT EXISTS artifacts (
    target_id INTEGER REFERENCES heats(id), -- = target id of judgement
    judge INTEGER REFERENCES dancers(id),
    artifact INTEGER NOT NULL, -- encoding of judgements
    PRIMARY KEY(target_id, judge)
);

CREATE TABLE IF NOT EXISTS bonus_artifacts (
    target_id INTEGER REFERENCES heats(id), -- = target id of judgement
    bonus INTEGER NOT NULL, -- encoding of bonus
    PRIMARY KEY(target_id)
);


-- TODO: could we spare couple tables with the same bid for both dancers in bib
CREATE TABLE IF NOT EXISTS couple_heats (
    id INTEGER PRIMARY KEY, -- = target id of judgement
    phase_id INTEGER REFERENCES phases(id),
    heat_number INTEGER NOT NULL,
    lead_dancer_id INTEGER REFERENCES dancers(id),
    follow_dancer_id INTEGER REFERENCES dancers(id),
    UNIQUE(phase_id, heat_number, lead_dancer_id, follow_dancer_id)
);

CREATE TABLE IF NOT EXISTS couple_artifacts (
    target_id INTEGER REFERENCES couple_heats(id), -- = target id of judgement
    judge INTEGER REFERENCES dancers(id),
    artifact INTEGER NOT NULL, -- encoding of judgements
    PRIMARY KEY(target_id, judge)
);

CREATE TABLE IF NOT EXISTS couple_bonus_artifacts (
    target_id INTEGER REFERENCES couple_heats(id), -- = target id of judgement
    bonus INTEGER NOT NULL, -- encoding of bonus
    PRIMARY KEY(target_id)
);

COMMIT;

