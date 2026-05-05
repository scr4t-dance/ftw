
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Event

(* DB interaction *)
(* ************************************************************************* *)

val last : st:State.t -> t
(** Last event *)

val list : st:State.t -> t list
(** List all events *)

val list_before : st:State.t -> n:int -> id:id -> t list
(** List events from one specific year *)

val get : st:State.t -> id -> t
(** Get an event from its id.
    @raise Stdlib.Not_found if the event is not found. *)

val create : st:State.t -> name:string -> short_name:string -> start_date:Date.t -> end_date:Date.t -> id
(** Create a new event. *)

val competitions : st:State.t -> t -> Competition.t list
(** Competitions that belong to an event. *)


(* Private functions *)
(* ************************************************************************* *)

module Private : sig

  include module type of Ftw_core.Event.Private

  val import : st:State.t -> id:id -> name:string -> short_name:string -> start_date:Date.t -> end_date:Date.t -> unit
  (** Import an event with a fixed id. *)

end
