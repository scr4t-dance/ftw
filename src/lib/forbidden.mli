
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Forbidden

(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> event:int -> t list

val set : st:State.t -> event:int -> t list -> unit

