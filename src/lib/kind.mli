
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
[@@deriving yojson]
(** Type for the kind of competitions. *)


(* DB interaction *)
(* ************************************************************************* *)

val to_int : t -> int
(** Conversion to integer. *)

val of_int : int -> t
(** Conversion from integer.
    @raise Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : t Conv.t
(** Converter for identifiers *)


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

