
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t = Id.t
(** Bibs are integers *)

type 'kind target =
  | Single :
      { target : Id.t; role : Role.t; } -> [`Single] target
  (** *)
  | Couple :
      { leader : Id.t; follower : Id.t; } -> [`Couple] target
  (** *)
(** The target that a bib can have: a bib can sometime refer to a single
    dancer (e.g. during a Jack&Jill), but also to a couple (e.g. in a
    Strictly). *)

type any_target = Any : _ target -> any_target
(** Existencial wrapper around the GADT. *)


(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> competition:Competition.id -> bib:t -> any_target option
(** Get the target of a bib, if it exists. *)

val set :
  st:State.t -> competition:Competition.id ->
  target:any_target -> bib:t -> unit
(** Set the bib for a given target in a competition. *)


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

