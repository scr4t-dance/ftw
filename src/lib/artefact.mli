
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr : sig

  type t =
    | Ranking
    | Yans of { criterion : string list; }
  [@@deriving yojson]
  (** Description of artefact types.*)

  val ranking : t
  val yans : string list -> t
  (** Construction functions *)

  val print : Format.formatter -> t -> unit
  (** Printing. *)

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)
end

(* Artefact type *)
(* ************************************************************************* *)

type yan =
  | Yes
  | Alt
  | No (**)
(* Yes/Alt/No *)

type t =
  | Rank of Rank.t
  | Yans of yan list

val check : descr:Descr.t -> t -> bool
(** Check whether an artefact matches a description. *)


(* DB Interaction *)
(* ************************************************************************* *)

val p : (int -> 'a, 'a) Sqlite3_utils.Ty.t
(** Sqlite query "type" for identifiers *)

val conv : descr:Descr.t -> t Conv.t
(** Converter for identifiers *)

val get :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  descr:Descr.t ->
  t

val set :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  t -> unit

val delete :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t -> unit


(* Serialization *)
(* ************************************************************************* *)

val to_toml : t -> Otoml.t
(** Serialization to toml. *)

val of_toml : descr:Descr.t -> Otoml.t -> t
(** Deserialization from toml.
    @raise Otoml.Type_error *)

module Targeted : sig

  type nonrec t = {
    judge: Judge.id;
    target : Id.t;
    artefact : t;
  }

  val to_toml : t -> Otoml.t
  (** Serialization to toml. *)

  val of_toml : descr:Descr.t -> Otoml.t -> t
  (** Deserialization from toml.
      @raise Otoml.Type_error *)

end
