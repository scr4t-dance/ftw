
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Routine         (** Routine:
                        Choregraphies (couples inscription + chosen music) *)
  | Strictly        (** Strictly:
                        inscription by couples, they stay together
                        throughout the competition. *)
  | JJ_Strictly     (** Jack&Jill Open-style:
                        individual inscription, random pairings in prelims,
                        the same pairings are kept throughout all the
                        competition. *)
  | Jack_and_Jill   (** Regular jack&Jill:
                        individual inscription, random pairing regenerated
                        at each phase. *)
(** Type for the kind of competitions. *)


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
