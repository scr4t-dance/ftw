
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Forbidden

(* DB interaction *)
(* ************************************************************************* *)

val conv : t Conv.t

val get : st:State.t -> competition:int -> t list

val set : st:State.t -> competition:int -> t list -> unit

