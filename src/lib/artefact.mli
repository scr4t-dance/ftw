
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr : sig

  type t =
    | Bonus
    | Ranking
    | Yans of { criterion : string list; }
  [@@deriving yojson]
  (** Description of artefact types.
      Enable reading of artefacts.*)  

  val bonus : t
  val ranking : t
  val yans : string list -> t
  val of_string : string -> t
  (** Conversion from string.
      @raise Failure _ if the string does not match spec *)
  val to_string : t -> string
  (** Conversion to string. *)
  val p : (string -> 'a, 'a) Sqlite3_utils.Ty.t
  (** Sqlite query "type" for identifiers *)
  
  val conv : t Conv.t
  (** Converter for identifiers *)
end

(* Artefact type *)
(* ************************************************************************* *)

type bonus = int
(* Bonus value *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type t =
  | Bonus of bonus
  | Rank of Rank.t
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


