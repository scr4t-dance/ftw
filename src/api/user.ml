
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Users *)
(* ************************************************************************* *)

type t = Db.User.t

let print = Db.User.print

let authenticate ~st ~username ~pwd =
  Db.User.authenticate ~st:(State.db st) ~username ~pwd

