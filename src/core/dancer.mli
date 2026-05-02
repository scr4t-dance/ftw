
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

val print : Format.formatter -> t -> unit
(** Compact printing. *)

val print_compact : Format.formatter -> t -> unit
(** Compact printing. *)

(* Private functions *)
(* ************************************************************************* *)

module Private : sig

  val mk :
    id:id -> last_name:string -> first_name:string ->
    birthday:Date.t option -> email:string option ->
    as_leader:Divisions.t -> as_follower:Divisions.t ->
    t

end
