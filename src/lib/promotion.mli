
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Promotion

(* DB interaction *)
(* ************************************************************************* *)

val record : st:State.t -> t -> unit
(** Record/add a promotion in the state, as well as update the division of the
    concerned dancer. *)


