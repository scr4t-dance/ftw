BEGIN TRANSACTION;

-- Step 1: Backup old tables by renaming
ALTER TABLE events RENAME TO events_backup;
ALTER TABLE competitions RENAME TO competitions_backup;

-- Step 2: Create updated `events` table
CREATE TABLE events (
  id INTEGER PRIMARY KEY,
  name TEXT,
  start_date TEXT,
  end_date TEXT,
  UNIQUE (name, start_date, end_date)
);

-- Step 3: Create updated `competitions` table
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

-- Step 4: Restore data from backups (shared columns only)
INSERT INTO events (id, name, start_date, end_date)
SELECT id, name, start_date, end_date FROM events_backup;

INSERT INTO competitions (id, event, name, kind, category)
SELECT id, event, name, kind, category FROM competitions_backup;

-- Step 5: Drop backup tables
DROP TABLE events_backup;
DROP TABLE competitions_backup;

COMMIT;
