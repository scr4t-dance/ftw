(lang dune 3.18)
(name ftw)
(using dune_site 0.1)
(generate_opam_files)

(source (github scr4t-dance/ftw))
(license GPLv3)
(authors "Guillaume Bury" "Xavier Duquesne")
(maintainers "Guillaume Bury")
(maintenance_intent "(latest)")

(package
 (name ftw)
 (synopsis "Scoring system for dancing competitions")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   (ftw-db  (= :version))
   (ftw-api (= :version))
   (ftw-bin (= :version))
   sqlite3 sqlite3_utils
   containers gen spelll otoml
   bos fpath logs fmt uunf uutf ubase
   jsont bytesrw argon2
   (fuzzy_match (>= v0.17.0))
   printbox printbox-text))

(package
 (name ftw-lib)
 (synopsis "Lib for the FTW scorign system")
 (description "TODO")
 (depends
   base sexplib0
   jsont))

(package
 (name ftw-db)
 (synopsis "Db for the FTW scoring system")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   base sexplib0
   jsont))

(package
 (name ftw-api)
 (synopsis "API definitions for the FTW scoring and points system")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   (ftw-db (= :version))
   base sexplib0
   jsont))

(package
 (name ftw-bin)
 (sites (share assets))
 (synopsis "Web server for the FTW scoring system")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   (ftw-db (= :version))
   (ftw-api (= :version))
   dream dream-html dream-htmx
   jsont bytesrw fuzzy_match
   (cmdliner (>= 1.3.0))
   logs fmt))

