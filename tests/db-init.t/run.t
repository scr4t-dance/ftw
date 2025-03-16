Database test
=====================

Init db
-------

test that database initialisation is reproducible

  $ echo "testing"
  testing
  $ sqlite3 backendexample.db < ../../src/backend/db-init.sql
  $ sqlite3 backendexample.db ".tables"
  artifacts               couple_artifacts        heats                 
  bibs                    couple_bonus_artifacts  judges                
  bonus_artifacts         couple_heats            judging_types         
  competition_categories  dancers                 phases                
  competition_kinds       divisions               round_types           
  competitions            events                
  $ rm backendexample.db
