
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type id = Id.t
(** Alias for ids *)

type t
(** The type of a dancer. *)


(* Accessors *)
(* ************************************************************************* *)

val id : t -> id
(** Dancer id. *)

val birthday : t -> Date.t option
(** Birthday (optional). *)

val last_name : t -> string
val first_name : t -> string
(** Names of the dancer. *)

val as_leader : t -> Divisions.t
val as_follower : t -> Divisions.t
(** Returns the divisions accessible to the given dancer, as a leader or
    a follower. *)


(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> id -> t
(** Get a Dancer from the database. *)

val add :
  st:State.t -> birthday:Date.t option ->
  first_name:string -> last_name:string -> email:string ->
  as_leader:Divisions.t -> as_follower:Divisions.t -> id
(** Add a dancer, and returns its id. *)


