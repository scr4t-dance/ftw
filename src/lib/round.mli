
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Prelims         (** Prelims: (optional) first round of a competition *)
  | Octofinals      (** Octofinals: (optional) round before quarterfinals *)
  | Quarterfinals   (** Quarterfinals: (optional) round before semifinals *)
  | Semifinals      (** Semifinals: (optinal) round before finals *)
  | Finals          (** Finals: Last round of any competition. *)
(** Type for the rounds of competitions, used to order phases.
    There cannot be two phases with the same round type in a competition. *)


(* Serialization *)
(* ************************************************************************* *)

val toml_key : t -> string
(** Suitable key for toml *)


(* DB interaction *)
(* ************************************************************************* *)

val to_int : t -> int
(** Conversion to integer. *)

val of_int : int -> t
(** Conversion from integer.
    @raise Stdlib.Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : t Conv.t
(** Converter for identifiers *)


(* Usual functions *)
(* ************************************************************************* *)

val print : Format.formatter -> t -> unit
(** Printing *)

val equal : t -> t -> bool
(** Equality function *)

val next : t -> t option
(** Get next round *)

val compare : t -> t -> int
(** Comparison function. *)

module Set : Set.S with type elt = t
(** Sets for identifiers *)

module Map : Map.S with type key = t
(** Maps for identifiers *)
