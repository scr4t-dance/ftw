
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definition *)
(* ************************************************************************* *)

(* TODO: consider adding a cache for some operations *)

type t = {
  db : Db.State.t;
}

(* Creation *)
(* ************************************************************************* *)

let mk ~init ~main_path ~user_path =
  let db = Db.State.mk ~init ~main_path ~user_path in
  { db; }


(* DB access *)
(* ************************************************************************* *)

let db t = t.db

