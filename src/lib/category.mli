
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type non_competitive =
  | Regular
  | Qualifying
  | Invited (**)
[@@deriving yojson]
(** Non competitive competitions, i.e. does not require or give points, but
    may grant access to some competititve divisions in some cases related
    to the creation of the point system. *)

type t =
  | Competitive of Division.t
  | Non_competitive of non_competitive (**)
[@@deriving yojson]
(** Type for division categories: either competitive (i.e. requires/gives
    access to points), or non-competitive (with some subdivision of those
    that mostly makes sense for the creation of the SCR4T point system). *)


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

