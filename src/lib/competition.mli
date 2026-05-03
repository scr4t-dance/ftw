
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Competition


(* DB interaction *)
(* ************************************************************************* *)

val conv : t Conv.t

val get : st:State.t -> id -> t
(** Get an event from its id.
    @raise Stdlib.Not_found if the competition is not found. *)

val from_event : st:State.t -> Ftw_core.Event.id -> t list
(** Get the list of all competitions that belong to a given event. *)

val ids_from_event : st:State.t -> Ftw_core.Event.id -> id list
(** Get the list of all competitions that belong to a given event. *)

val create :
  st:State.t ->
  event_id:Ftw_core.Event.id -> ?check_divs:bool ->
  name:string -> kind:Kind.t -> category:Category.t ->
  n_leaders:int -> n_follows:int -> unit -> t
(** Create a new competition *)


val phases : st:State.t -> t -> Phase.t list

val round : st:State.t -> t -> Round.t -> Phase.t option


(* Private functions *)
(* ************************************************************************* *)

module Private :sig

  include module type of Ftw_core.Competition.Private

  val import :
    st:State.t -> id:id ->
    event_id:Ftw_core.Event.id -> ?check_divs:bool ->
    name:string -> kind:Kind.t -> category:Category.t ->
    n_leaders:int -> n_follows:int -> unit -> unit
    (** Import a competition (including id). *)

end
