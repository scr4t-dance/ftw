
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | None
  | Novice
  | Novice_Intermediate
  | Intermediate
  | Intermediate_Advanced
  | Advanced (**)
(** This represents the divisions accessible to a given dancer. Semantically,
    the [None] and [Novice] divisions are equivalent, but [None] is the
    initial divisions for dancers that have not yet danced in a role.
    (e.g. a novice main lead might have [Novice] divisions as leader,
    but [None] divisions as follower). *)


(* Usual functions *)
(* ************************************************************************* *)

val equal : t -> t -> bool
val compare : t -> t -> int
val max : t -> t -> t
val print : Format.formatter -> t -> unit

val includes : Division.t -> t -> bool


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


