
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type non_competitive =
  | Regular
  | Qualifying
  | Invited (**)
(** Non competitive competitions, i.e. does not require or give points, but
    may grant access to some competititve divisions in some cases related
    to the creation of the point system. *)

type t =
  | Competitive of Division.t
  | Non_competitive of non_competitive (**)
(** Type for division categories: either competitive (i.e. requires/gives
    access to points), or non-competitive (with some subdivision of those
    that mostly makes sense for the creation of the SCR4T point system). *)

(* Usual functions *)
(* ************************************************************************* *)

val print : Format.formatter -> t -> unit
(** Printing function (note: for debug only). *)

val equal : t -> t -> bool
(** Equality function *)

val compare : t -> t -> int
(** Comparison function. *)

module Set : Set.S with type elt = t
(** Sets for identifiers *)

module Map : Map.S with type key = t
(** Maps for identifiers *)
