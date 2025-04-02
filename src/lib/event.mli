
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
(** Unique id for the event *)

val name : t -> string
(** Name of the event *)

val start_date : t -> Date.t
(** Start date of the event *)

val end_date : t -> Date.t
(** End date of the event. *)

val compare : t -> t -> int
(** Comparison function. Compares the date before *)

val print_compact : Format.formatter -> t -> unit
(** Compact printing. *)


(* DB interaction *)
(* ************************************************************************* *)

val list : State.t -> t list
(** List all events *)

val get : State.t -> id -> t
(** Get an event from its id.
    @raise Not_found if the event is not found. *)

val create : State.t -> string -> start_date:Date.t -> end_date:Date.t -> id
(** Create a new event. *)

