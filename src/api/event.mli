
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

val create :
  st:State.t -> ?user:User.t ->
  name:string -> short_name:string ->
  start_date:Lib.Date.t -> end_date:Lib.Date.t ->
  public:bool -> status:Lib.Event.status ->
  unit -> Lib.Event.id res
