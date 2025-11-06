Database test
=====================

Init db
-------

test that database initialisation is reproducible

Launch the FTW server in the background

  $ ftw --db=route_test.db --port=8082 > /dev/null 2>&1 &

Sleep a bit to ensure that the server had had time to initialize and is ready
to respond to requests

  $ sleep 1

Run a query to init database

  $ curl -s http://localhost:8082/api/events
  {"events":[]}

Print schema
If the definition changes
* bump version number in src/lib/state.ml
* promote changes
* save new schema in src/migration/schema_V.sql (with V the version number)
* create migration script src/migration/migrate_V-1_to_V.sql
* apply to existing database and tests data integrity (with a round trip of exported/imported data)
  $ sqlite3 "route_test.db" '.schema'
  CREATE TABLE round_names (
          id INTEGER PRIMARY KEY,
          name TEXT UNIQUE);
  CREATE TABLE division_names (
          id INTEGER PRIMARY KEY,
          name TEXT UNIQUE);
  CREATE TABLE divisions_names (
          id INTEGER PRIMARY KEY,
          name TEXT UNIQUE);
  CREATE TABLE dancers (
            id INTEGER PRIMARY KEY,
            birthday TEXT,
            last_name TEXT,
            first_name TEXT,
            email TEXT,
            as_leader INTEGER REFERENCES divisions_names(id),
            as_follower INTEGER REFERENCES divisions_names(id)
          );
  CREATE TABLE judging_names (
          id INTEGER PRIMARY KEY,
          name TEXT UNIQUE);
  CREATE TABLE judges (
            judge_id INTEGER REFERENCES dancers(id),
            phase_id INTEGER REFERENCES phases(id),
            judging INTEGER REFERENCES judging_names(id),

            PRIMARY KEY(judge_id, phase_id)
          );
  CREATE TABLE artefacts (
            target_id INTEGER REFERENCES heats(id) ON DELETE CASCADE,
            judge INTEGER REFERENCES dancers(id),
            artefact INTEGER NOT NULL,
            PRIMARY KEY(target_id,judge)
            ON CONFLICT REPLACE
          );
  CREATE TABLE bonus (
            target_id INTEGER REFERENCES heats(id), -- = target id of judgement
            bonus INTEGER NOT NULL,
            PRIMARY KEY(target_id)
          );
  CREATE TABLE competition_categories (
          id INTEGER PRIMARY KEY,
          name TEXT UNIQUE);
  CREATE TABLE events (
            id INTEGER PRIMARY KEY,
            name TEXT,
            short_name TEXT,
            start_date TEXT,
            end_date TEXT,
            UNIQUE (name, start_date, end_date)
          );
  CREATE TABLE competition_kinds (
          id INTEGER PRIMARY KEY,
          name TEXT UNIQUE);
  CREATE TABLE competitions (
            id INTEGER PRIMARY KEY,
            event INTEGER REFERENCES events(id),
            name TEXT,
            kind INTEGER REFERENCES competition_kinds(id),
            category INTEGER REFERENCES competition_categories(id),
            num_leaders INTEGER,
            num_followers INTEGER,
            check_divs INTEGER
          );
  CREATE TABLE phases (
            id INTEGER PRIMARY KEY,
            competition_id INT REFERENCES competitions(id),
            round INTEGER REFERENCES round_names(id),
            judge_artefact_descr TEXT,
            head_judge_artefact_descr TEXT,
            ranking_algorithm TEXT,
            UNIQUE(competition_id, round)
          );
  CREATE TABLE heats (
            id INTEGER PRIMARY KEY,
            phase_id INTEGER NOT NULL REFERENCES phases(id),
            heat_number INTEGER NOT NULL,
            leader_id INTEGER REFERENCES dancers(id),
            follower_id INTEGER REFERENCES dancers(id)
          );
  CREATE TABLE results (
            competition INTEGER REFERENCES competitions(id),
            dancer INTEGER REFERENCES dancers(id),
            role INTEGER,
            result INTEGER,
            points INTEGER,
            PRIMARY KEY (competition, dancer, role)
          );
  CREATE TABLE bibs (
            dancer_id INTEGER REFERENCES dancers(id),
            competition_id INTEGER REFERENCES competitions(id),
            bib INTEGER NOT NULL,
            role INTEGER NOT NULL,

            PRIMARY KEY(bib,competition_id,role)
          );


End & Cleanup
-------------

Make sure all children of this process have been killed,
especially the FTW server in the background

  $ pkill -P "$$"
