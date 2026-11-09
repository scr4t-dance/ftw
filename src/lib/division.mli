
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Novice        (** division Initié *)
  | Intermediate  (** division Inter *)
  | Advanced      (** division Avancé *)
(** Type for the competitive divisions; these are the divisions for which
    the SCR4T defines points and promotion rules. *)


(* Usual functions *)
(* ************************************************************************* *)

val equal : t -> t -> bool
(** Equality function *)

val compare : t -> t -> int
(** Comparison function. *)

val print : Format.formatter -> t -> unit
(** Print function *)

module Set : Set.S with type elt = t
(** Sets for identifiers *)

module Map : Map.S with type key = t
(** Maps for identifiers *)
