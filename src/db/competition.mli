
(* This file is free software, part of FTW. See file "LICENSE" for more information *)


(* DB read *)
(* ************************************************************************* *)

val conv : Lib.Competition.t Conv.t

val get : st:State.t -> Lib.Competition.id -> Lib.Competition.t
(** Get an event from its id.
    @raise Stdlib.Not_found if the competition is not found. *)

val from_event : st:State.t -> Lib.Event.id -> Lib.Competition.t list
(** Get the list of all competitions that belong to a given event. *)

val ids_from_event : st:State.t -> Lib.Event.id -> Lib.Competition.id list
(** Get the list of all competitions that belong to a given event. *)

val phases : st:State.t -> Lib.Competition.t -> Lib.Phase.t list

val round : st:State.t -> Lib.Competition.t -> Lib.Round.t -> Lib.Phase.t option


(* DB writes *)
(* ************************************************************************* *)

val create :
  st:State.t -> event_id:Lib.Event.id ->
  status:Lib.Competition.status -> public:bool -> ?check_divs:bool ->
  name:string -> kind:Lib.Kind.t -> category:Lib.Category.t ->
  n_leaders:int -> n_follows:int -> unit -> Lib.Competition.t
(** Create a new competition *)

val update : st:State.t -> Lib.Competition.t -> unit


(* Private functions *)
(* ************************************************************************* *)

module Private :sig

  val import :
    st:State.t -> id:Lib.Competition.id -> status:Lib.Competition.status -> public:bool ->
    event_id:Lib.Event.id -> ?check_divs:bool ->
    name:string -> kind:Lib.Kind.t -> category:Lib.Category.t ->
    n_leaders:int -> n_follows:int -> unit -> unit
    (** Import a competition (including id). *)

end
