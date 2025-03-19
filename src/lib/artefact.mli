
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

(* Artefact descriptions *)
(* ************************************************************************* *)

module Descr : sig

  type t =
    | Ranking
    | Yans of { criterion : string list; }
  [@@deriving yojson]

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

val get_regular :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  descr:Descr.t ->
  t

val set_regular :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  t -> unit

val get_jack_strictly :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  descr:Descr.t ->
  t

val set_jack_strictly :
  st:State.t ->
  judge:Judge.id ->
  target:Id.t ->
  t -> unit

