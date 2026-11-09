
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Module aliases *)
(* ************************************************************************* *)

module Db = Ftw_db
module Lib = Ftw_lib

(* Monadic operators *)
(* ************************************************************************* *)

let ( let$ ) f x = f x
