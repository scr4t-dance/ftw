
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t [@@deriving yojson]
(** Alias for ids *)

type t
(** The type of a dancer. *)


(* Accessors *)
(* ************************************************************************* *)

val id : t -> id
(** Dancer id. *)

val birthday : t -> Date.t option
(** Email & Birthday (optional). *)

val last_name : t -> string
val first_name : t -> string
(** Names of the dancer. *)

val email : t -> string option
(** email of the dancer. *)

val as_leader : t -> Divisions.t
val as_follower : t -> Divisions.t
(** Returns the divisions accessible to the given dancer, as a leader or
    a follower. *)

val print_compact : Format.formatter -> t -> unit
(** Compact printing. *)


(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> id -> t
(** Get a Dancer from the database. *)

val add :
  st:State.t -> ?birthday:Date.t ->
  first_name:string -> last_name:string -> ?email:string ->
  as_leader:Divisions.t -> as_follower:Divisions.t -> unit -> t
(** Add a dancer, and returns its id. *)

val update :
  st:State.t -> id_dancer:id -> ?birthday:Date.t ->
  first_name:string -> last_name:string -> ?email:string ->
  as_leader:Divisions.t -> as_follower:Divisions.t -> unit -> t
(** Update dancer, and returns its id. *)

val update_divisions :
  st:State.t -> dancer:id -> role:Role.t -> divs:Divisions.t -> unit
(** Update divisions for a dancer. *)

val for_all : st:State.t -> f:(t -> unit) -> unit
(** Iterate over all dancers. *)

val list : st:State.t -> t list

(* Index *)
(* ************************************************************************* *)

module Index : sig

  type dancer = t
  (** Alias for the type of dancers. *)

  type t
  (** The type of indexes *)

  type res =
    | Found of dancer
    | Not_found of { suggestions : dancer list; } (**)
  (** *)

  val empty : t
  (** The empty index. *)

  val mk : st:State.t -> t
  (** Create an index from a state. *)

  val add : dancer -> t -> t
  (** Add a dancer to the index. *)

  val find : t -> first_name:string -> last_name:string -> res
  (** Lookup in the index. Can return a suggested list of dancers with
      close names to the ones that were given. *)

end
