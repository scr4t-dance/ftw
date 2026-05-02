
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Dancer


(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t
(** Serialization to toml. Does not include the leader/follower divisions. *)

val of_toml : Otoml.t -> t
(** Deserialization from toml. Sets the leader/follower divisions to [None].
    @raise Otoml.Type_error *)


(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> id -> t
(** Get a Dancer from the database. *)

val add :
  st:State.t ->
  first_name:string -> last_name:string ->
  ?birthday:Date.t -> ?email:string ->
  as_leader:Divisions.t -> as_follower:Divisions.t ->
  unit -> t
(** Add a dancer, and returns the dancer data saved in the database. *)

val update :
  st:State.t -> id_dancer:id -> ?birthday:Date.t ->
  first_name:string -> last_name:string -> ?email:string ->
  as_leader:Divisions.t -> as_follower:Divisions.t -> unit -> unit
(** Update dancer. *)

val update_divisions :
  st:State.t -> dancer:id -> role:Role.t -> divs:Divisions.t -> unit
(** Update divisions for a dancer. *)

val for_all : st:State.t -> f:(t -> unit) -> unit
(** Iterate over all dancers. *)

val list : st:State.t -> t list
(* List of all dancers *)


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

  val find : ?limit:int -> t -> first_name:string -> last_name:string -> res
  (** Lookup in the index. Can return a suggested list of dancers with
      close names to the ones that were given. *)

end

(* Private functions *)
(* ************************************************************************* *)

module Private : sig

  include module type of Ftw_core.Dancer.Private

  val import :
    st:State.t -> id:Id.t ->
    first_name:string -> last_name:string ->
    ?birthday:Date.t -> ?email:string ->
    as_leader:Divisions.t -> as_follower:Divisions.t ->
    unit -> unit
    (** Import a dancer, including its unique id. May fail if the id is already used. *)


end
