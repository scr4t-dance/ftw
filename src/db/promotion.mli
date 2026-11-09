
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* DB interaction *)
(* ************************************************************************* *)

val record : st:State.t -> Lib.Promotion.t -> unit
(** Record/add a promotion in the state, as well as update the division of the
    concerned dancer. *)

val find : st:State.t ->
  [ `Dancer of Lib.Dancer.t | `Event of Lib.Event.t ] -> Lib.Promotion.t list

