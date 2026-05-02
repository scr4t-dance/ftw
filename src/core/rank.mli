
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t
(** A rank. *)


(* Conversions *)
(* ************************************************************************* *)

val mk : int -> t
val rank : t -> int
(* Human-readable conversions: the first place is the int [1], and so on ...*)

val of_index : int -> t
val to_index : t -> int
(* Conversions to/from indexes, where the first rank is [0] *)

val next : t -> t
(** Next rank *)


(* Usual functions *)
(* ************************************************************************* *)

val print : Format.formatter -> t -> unit
(** Print *)

val equal : t -> t -> bool
(** Equality function *)

val compare : t -> t -> int
(** Comparison function. *)

val min : t -> t -> t
(** Minimum of two ranks, smaller ranks are "better"
    (i.e. first place is the smallest rank) *)

module Set : Set.S with type elt = t
(** Sets for identifiers *)

module Map : Map.S with type key = t
(** Maps for identifiers *)

