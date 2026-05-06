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
 (synopsis "Library for the FTW scoring and points system")
 (description "TODO")
 (depends
   sqlite3 sqlite3_utils
   containers gen spelll otoml
   bos fpath logs fmt uunf uutf
   jsont bytesrw fuzzy_match
   printbox printbox-text))

(package
 (name ftw-api)
 (synopsis "API definitions for the FTW scoring and points system")
 (description "TODO")
 (depends
   (ftw (= :version))
   base sexplib0
   jsont))

(package
 (name ftw-server)
 (sites (share assets))
 (synopsis "Web server for the FTW scoring system")
 (description "TODO")
 (depends
   (ftw (= :version))
   dream dream-html dream-htmx
   jsont bytesrw fuzzy_match
   (cmdliner (>= 1.3.0))
   logs fmt))
