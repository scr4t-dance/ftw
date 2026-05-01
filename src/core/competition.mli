
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]
(** Ids for events *)

type t
(** Events *)


(* Common functions *)
(* ************************************************************************* *)

val id : t -> id
(** Unique id for the competition. *)

val name : t -> string
(** Name of the competition *)

val event : t -> Event.id
(** Parent event for the competition. *)

val kind : t -> Kind.t
(** Kind of the competition. *)

val category : t -> Category.t
(** Category for the competition. *)

val n_leaders : t -> int
val n_follows : t -> int
(** Number of leaders and follows that participated in the competition.
    Note that in some cases (mostly for old competitions), this information
    may be missing and therefore this will return [0]. *)

val check_divs : t -> bool
(** Should the competition check the divisoin of participants ? This is only
    set to [false] for old competitions during the introduction of the SCR4T
    competitive point system. *)

val print_compact : Format.formatter -> t -> unit
(** Compact printing *)


(* DB interaction *)
(* ************************************************************************* *)

val get : State.t -> id -> t
(** Get an event from its id.
    @raise Stdlib.Not_found if the competition is not found. *)

val from_event : State.t -> Event.id -> t list
(** Get the list of all competitions that belong to a given event. *)

val ids_from_event : State.t -> Event.id -> id list
(** Get the list of all competitions that belong to a given event. *)

val create :
  st:State.t ->
  event_id:Event.id -> ?check_divs:bool ->
  name:string -> kind:Kind.t -> category:Category.t ->
  n_leaders:int -> n_follows:int -> unit -> t
(** Create a new competition *)

val import :
  st:State.t -> id:id ->
  event_id:Event.id -> ?check_divs:bool ->
  name:string -> kind:Kind.t -> category:Category.t ->
  n_leaders:int -> n_follows:int -> unit -> unit
(** Import a competition (including id). *)

val ids_from_dancer_history : State.t -> Dancer.id -> id list
(** Get the list of all competitions a dancer participated in. *)

val update_competitors_number : st:State.t -> id:id -> n_leaders:id -> n_followers:id -> unit
