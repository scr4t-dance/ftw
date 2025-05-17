CREATE TABLE database_version (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE);
CREATE TABLE round_names (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE);
CREATE TABLE division_names (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE);
CREATE TABLE competition_categories (
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE);
CREATE TABLE events (
          id INTEGER PRIMARY KEY,
          name TEXT,
          start_date TEXT,
          end_date TEXT,
          UNIQUE (name, start_date, end_date)
        );
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
CREATE TABLE results (
          competition INTEGER REFERENCES competitions(id),
          dancer INTEGER REFERENCES dancers(id),
          role INTEGER,
          result INTEGER,
          points INTEGER,
          PRIMARY KEY (competition, dancer, role)
        );
CREATE TABLE artefacts (
          target_id INTEGER REFERENCES heats(id),
          judge INTEGER REFERENCES dancers(id),
          artefact INTEGER NOT NULL,
          PRIMARY KEY(target_id,judge)
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
CREATE TABLE bibs (
          dancer_id INTEGER REFERENCES dancers(id),
          competition_id INTEGER REFERENCES competitions(id),
          bib INTEGER NOT NULL,
          role INTEGER NOT NULL,

          PRIMARY KEY(bib,competition_id,role)
        );
