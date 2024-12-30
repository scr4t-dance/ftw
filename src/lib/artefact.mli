
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr : sig

  type t =
    | Bonus
    | Ranking
    | Yans of { criterion : string list; }

  val bonus : t
  val ranking : t
  val yans : string list -> t

end

(* Artefact type *)
(* ************************************************************************* *)

type bonus = int
(* Bonus value *)

type rank = int
(* ranks, from 1 to <n> (for some <n>) *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type t =
  | Bonus of bonus
  | Rank of rank
  | Yans of yan list

(* DB Interaction *)
(* ************************************************************************* *)

val to_int : t -> int
(** Conversion to integer. *)

val of_int : descr:Descr.t -> int -> t
(** Conversion from integer.
    @raise Failure _ if the int is out of range *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : descr:Descr.t -> t Conv.t
(** Converter for identifiers *)


