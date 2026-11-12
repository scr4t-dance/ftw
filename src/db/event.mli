
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

open! Syntax

(* DB interaction *)
(* ************************************************************************* *)

val get :
  st:State.t -> Lib.Event.id -> Lib.Event.t Syntax.res
(** Get an event from its id.
    @raise Stdlib.Not_found if the event is not found. *)

val list_before :
  st:State.t -> n:int -> Lib.Event.id option -> Lib.Event.id list res
(** List events from one specific year *)




val list : st:State.t -> Lib.Event.t list
(** List all events *)

val create : st:State.t ->
  name:string -> short_name:string ->
  start_date:Lib.Date.t -> end_date:Lib.Date.t ->
  public:bool -> status:Lib.Event.status ->
  Lib.Event.id
(** Create a new event. *)

val update : st:State.t -> Lib.Event.t -> unit
(** Update an event. *)

val competitions : st:State.t -> Lib.Event.t -> Lib.Competition.t list
(** Competitions that belong to an event. *)


(* Private functions *)
(* ************************************************************************* *)

module Private : sig

  val import : st:State.t -> id:Lib.Event.id ->
    name:string -> short_name:string ->
    start_date:Lib.Date.t -> end_date:Lib.Date.t ->
    public:bool -> status:Lib.Event.status ->
    unit
  (** Import an event with a fixed id. *)

end
