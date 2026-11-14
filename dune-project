(lang dune 3.18)
(name ftw)
(using dune_site 0.1)
(generate_opam_files)

(source (github scr4t-dance/ftw))
(license GPL-3.0-only)
(authors "Guillaume Bury" "Xavier Duquesne")
(maintainers "Guillaume Bury")
(maintenance_intent "(latest)")

(package
 (name ftw)
 (synopsis "Scoring system for dancing competitions")
 (description "Meta package to install all of the FTW packages")
 (allow_empty)
 (depends
   (ftw-lib (= :version))
   (ftw-db  (= :version))
   (ftw-api (= :version))
   (ftw-bin (= :version))
 ))

(package
 (name ftw-lib)
 (synopsis "Lib for the FTW scorign system")
 (description "TODO")
 (depends
   fmt logs
   ppx_compare
   jsont bytesrw
   containers gen spelll otoml
   printbox printbox-text
 ))

(package
 (name ftw-db)
 (synopsis "Db for the FTW scoring system")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   fmt logs
   containers gen argon2
   spelll otoml uutf uunf ubase
   (fuzzy_match (>= v0.17.0))
   ppx_deriving sqlite3 sqlite3_utils
 ))

(package
 (name ftw-api)
 (synopsis "API definitions for the FTW scoring and points system")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   (ftw-db  (= :version))
   fmt logs containers
 ))

(package
 (name ftw-bin)
 (sites (share assets))
 (synopsis "Web server for the FTW scoring system")
 (description "TODO")
 (depends
   (ftw-lib (= :version))
   (ftw-db  (= :version))
   (ftw-api (= :version))
   dream dream-html dream-htmx
   fmt logs containers
   (cmdliner (>= 1.3.0))
   dune-site
 ))

