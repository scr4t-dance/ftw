
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax

(* Events API *)
(* ************************************************************************* *)

(** Get an event details from its id. *)
val get :
  st:State.t -> ?user:User.t ->
  Lib.Event.id -> Lib.Event.t res

val list_before :
  st:State.t -> ?user:User.t ->
  n:int -> Lib.Event.id option -> Lib.Event.id list res
