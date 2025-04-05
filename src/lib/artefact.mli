
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr : sig

  type t =
    | Ranking
    | Yans of { criterion : string list; }
  [@@deriving yojson]
  (** Description of artefact types.
      Enable reading of artefacts.*)

  val ranking : t
  val yans : string list -> t

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

(* DB Interaction *)
(* ************************************************************************* *)

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
