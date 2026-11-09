
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> event:int -> Lib.Forbidden.t list

val set : st:State.t -> event:int -> Lib.Forbidden.t list -> unit

