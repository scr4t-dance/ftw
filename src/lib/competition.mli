
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


(* DB interaction *)
(* ************************************************************************* *)

val get : State.t -> id -> t
(** Get an event from its id.
    @raise Not_found if the competition is not found. *)

val from_event : State.t -> Event.id -> t list
(** Get the list of all competitions that belong to a given event. *)

val create : State.t -> Event.id -> string -> Kind.t -> Category.t -> id
(** Create a new competition *)

