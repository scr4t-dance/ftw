API Full Session Test
=====================

Initialization
--------------

Import data
  $ dune exec -- ftw import --db=test_import.db bib.toml


  $ sqlite3 "test_import.db" 'select * from bibs order by competition_id, bib'
  1|1|103|1
  2|1|203|0
  3|2|102|1
  4|2|202|0
  5|3|101|1
  6|3|201|0
