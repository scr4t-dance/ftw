
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = Id.t
(** Bibs are integers *)


(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> competition:Competition.id -> bib:t -> Id.t Target.any option
(** Get the target of a bib, if it exists. *)

val get_all : st:State.t -> competition:Competition.id -> (t * Id.t Target.any) list
(** Get all bibs from a competition *)

val add :
  st:State.t -> competition:Competition.id ->
  target:Id.t Target.any -> bib:t -> unit
(** Set the bib for a given target in a competition.

    The primary key for bib table is bib,competition_id,role.
    It allows to work with either
    * same bib for dancer as lead and follow
    * different bibs for leaders and followers
*)

val delete :
  st:State.t -> competition:Competition.id ->
  bib:t -> unit
(** Update the bib for a given target in a competition. *)


val update :
  st:State.t -> competition:Competition.id ->
  old_bib:t ->
  new_bib:t -> unit
(** Update the bib for a given target in a competition. *)


(* Usual functions *)
(* ************************************************************************* *)

val equal : t -> t -> bool
(** Equality function *)

val compare : t -> t -> int
(** Comparison function. *)

module Set : Set.S with type elt = t
(** Sets for identifiers *)

module Map : Map.S with type key = t
(** Maps for identifiers *)
