
(* This file is free software, part of FTW. See file "LICENSE" for more information *)

include module type of Ftw_core.Phase

(* DB interaction *)
(* ************************************************************************* *)

val get : st:State.t -> id -> t
(** Get an event from its id.
    @raise Stdlib.Not_found if the phase is not found. *)

val create :
  st:State.t -> Competition.id -> Round.t ->
  ranking_algorithm:Ranking.Algorithm.t ->
  judge_artefact_descr:Artefact.Descr.t ->
  head_judge_artefact_descr:Artefact.Descr.t ->
  t
(** Create a new phase *)

val update : st:State.t -> id ->
  ranking_algorithm:Ranking.Algorithm.t ->
  judge_artefact_descr:Artefact.Descr.t ->
  head_judge_artefact_descr:Artefact.Descr.t ->
  unit
(** Update the details of a phase. *)

val delete : st:State.t -> id -> id
(** Delete a phase.
    TODO: delete more than phase.
    TODO: soft delete ?
*)
