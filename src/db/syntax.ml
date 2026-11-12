
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Import *)
(* ************************************************************************* *)

include Lib.Syntax

let ( let@? ) frame f = with_ctx frame (Db.wrap f)

