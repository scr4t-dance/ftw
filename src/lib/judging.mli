
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Type definitions *)
(* ************************************************************************* *)

type t =
  | Head
  | Leaders
  | Followers
  | Couples (**)
(** The type of "judging", i.e. what/who does a Judge scores.
    * Head means both leaders and followers are judged. Additionally,
      the head judge's notes are used to break up ties.
    * Leaders
    * Followers
    * Couples means the pair of dancers is judged together
*)

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
