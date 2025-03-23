
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Prelims         (** Prelims:
                        If a competition requires 2 rounds or more,
                        the first round is always called Prelims *)
  | Octofinals      (** Octofinals:
                        If a competition requires 5 rounds or more,
                        the round before the Quarterfinals is called Octofinals *)
  | Quarterfinals   (** Quarterfinals:
                        If a competition requires 4 rounds or more,
                        the round before the Semifinals is called Quarterfinals *)
  | Semifinals      (** Semifinals:
                        If a competition requires 3 rounds or more,
                        the round before the finals is called Semifinals *)
  | Finals          (** Finals:
                        Last round of any competition *)
[@@deriving yojson, enum]
(** Type for the rounds of competitions, used to order phases.
    There cannot be two phases with the same round type in a competition.*)


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

