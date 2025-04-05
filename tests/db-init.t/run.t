Database test
=====================

Init db
-------

test that database initialisation is reproducible

  $ echo "testing"
  testing
  $ sqlite3 backendexample.db < ../../src/backend/db-init.sql
  $ sqlite3 backendexample.db ".tables"
  artefacts               couple_artefacts        heats                 
  bibs                    couple_bonus_artefacts  judges                
  bonus_artefacts         couple_heats            judging_types         
  competition_categories  dancers                 phases                
  competition_kinds       division_names          rounds                
  competitions            events                
  $ rm backendexample.db
